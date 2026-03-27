using glxt.Data;
using glxt.Models;
using glxt.Models.DTOs;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace glxt.Services.Implementations
{
    public class ChatGroupService : IChatGroupService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<ChatGroupService> _logger;

        public ChatGroupService(ApplicationDbContext db, ILogger<ChatGroupService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<ChatGroupResponseDto> CreateGroupAsync(int creatorId, CreateChatGroupDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
                throw new ArgumentException("群组名称不能为空");

            // 创建群组
            var group = new ChatGroup
            {
                Name = dto.Name,
                Description = dto.Description,
                CreatorId = creatorId,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _db.ChatGroups.Add(group);
            await _db.SaveChangesAsync();

            // 添加创建者为群主
            var creatorMember = new ChatGroupMember
            {
                ChatGroupId = group.Id,
                UserId = creatorId,
                Role = MemberRole.Owner,
                JoinedAt = DateTime.UtcNow,
                IsActive = true
            };
            _db.ChatGroupMembers.Add(creatorMember);

            // 添加其他成员
            if (dto.MemberUsernames != null && dto.MemberUsernames.Any())
            {
                var users = await _db.Users
                    .Where(u => dto.MemberUsernames.Contains(u.Username) && u.Id != creatorId)
                    .ToListAsync();

                foreach (var user in users)
                {
                    var member = new ChatGroupMember
                    {
                        ChatGroupId = group.Id,
                        UserId = user.Id,
                        Role = MemberRole.Member,
                        JoinedAt = DateTime.UtcNow,
                        IsActive = true
                    };
                    _db.ChatGroupMembers.Add(member);
                }
            }

            await _db.SaveChangesAsync();

            // 返回群组信息
            return await GetGroupByIdAsync(group.Id, creatorId) 
                ?? throw new InvalidOperationException("创建群组后无法获取信息");
        }

        public async Task<ChatGroupResponseDto?> GetGroupByIdAsync(int groupId, int userId)
        {
            // 检查用户是否是群成员
            var isMember = await _db.ChatGroupMembers
                .AnyAsync(m => m.ChatGroupId == groupId && m.UserId == userId && m.IsActive);

            if (!isMember)
                return null;

            var group = await _db.ChatGroups
                .Include(g => g.Creator)
                .Include(g => g.Members.Where(m => m.IsActive))
                    .ThenInclude(m => m.User)
                .FirstOrDefaultAsync(g => g.Id == groupId && g.IsActive);

            if (group == null)
                return null;

            return new ChatGroupResponseDto
            {
                Id = group.Id,
                Name = group.Name,
                Description = group.Description,
                AvatarUrl = group.AvatarUrl,
                CreatorId = group.CreatorId,
                CreatedAt = group.CreatedAt,
                MemberCount = group.Members.Count,
                Members = group.Members.Select(m => new GroupMemberDto
                {
                    UserId = m.UserId,
                    Username = m.User.Username,
                    FullName = m.User.FullName,
                    Role = m.Role,
                    JoinedAt = m.JoinedAt
                }).ToList()
            };
        }

        public async Task<List<ChatGroupResponseDto>> GetUserGroupsAsync(int userId)
        {
            var groupIds = await _db.ChatGroupMembers
                .Where(m => m.UserId == userId && m.IsActive)
                .Select(m => m.ChatGroupId)
                .ToListAsync();

            var groups = await _db.ChatGroups
                .Include(g => g.Creator)
                .Include(g => g.Members.Where(m => m.IsActive))
                    .ThenInclude(m => m.User)
                .Where(g => groupIds.Contains(g.Id) && g.IsActive)
                .OrderByDescending(g => g.CreatedAt)
                .ToListAsync();

            return groups.Select(g => new ChatGroupResponseDto
            {
                Id = g.Id,
                Name = g.Name,
                Description = g.Description,
                AvatarUrl = g.AvatarUrl,
                CreatorId = g.CreatorId,
                CreatedAt = g.CreatedAt,
                MemberCount = g.Members.Count,
                Members = g.Members.Select(m => new GroupMemberDto
                {
                    UserId = m.UserId,
                    Username = m.User.Username,
                    FullName = m.User.FullName,
                    Role = m.Role,
                    JoinedAt = m.JoinedAt
                }).ToList()
            }).ToList();
        }

        public async Task<bool> AddMembersAsync(int groupId, int operatorId, List<string> usernames)
        {
            // 检查操作者权限（必须是Owner或Admin）
            var operatorMember = await _db.ChatGroupMembers
                .FirstOrDefaultAsync(m => m.ChatGroupId == groupId && m.UserId == operatorId && m.IsActive);

            if (operatorMember == null || 
                (operatorMember.Role != MemberRole.Owner && operatorMember.Role != MemberRole.Admin))
                throw new UnauthorizedAccessException("无权限添加成员");

            var users = await _db.Users
                .Where(u => usernames.Contains(u.Username))
                .ToListAsync();

            // 检查哪些用户已经是成员
            var existingMemberIds = await _db.ChatGroupMembers
                .Where(m => m.ChatGroupId == groupId && m.IsActive)
                .Select(m => m.UserId)
                .ToListAsync();

            var newUsers = users.Where(u => !existingMemberIds.Contains(u.Id));

            foreach (var user in newUsers)
            {
                var member = new ChatGroupMember
                {
                    ChatGroupId = groupId,
                    UserId = user.Id,
                    Role = MemberRole.Member,
                    JoinedAt = DateTime.UtcNow,
                    IsActive = true
                };
                _db.ChatGroupMembers.Add(member);

                // 发送系统消息
                var systemMessage = new ChatMessage
                {
                    SenderId = operatorId,
                    ChatGroupId = groupId,
                    MessageType = MessageType.System,
                    Content = $"{user.Username} 加入了群聊",
                    SentAt = DateTime.UtcNow
                };
                _db.ChatMessages.Add(systemMessage);
            }

            await _db.SaveChangesAsync();
            return true;
        }

        public async Task<bool> RemoveMemberAsync(int groupId, int operatorId, int memberId)
        {
            // 检查操作者权限
            var operatorMember = await _db.ChatGroupMembers
                .FirstOrDefaultAsync(m => m.ChatGroupId == groupId && m.UserId == operatorId && m.IsActive);

            if (operatorMember == null || 
                (operatorMember.Role != MemberRole.Owner && operatorMember.Role != MemberRole.Admin))
                throw new UnauthorizedAccessException("无权限移除成员");

            var member = await _db.ChatGroupMembers
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.ChatGroupId == groupId && m.UserId == memberId && m.IsActive);

            if (member == null)
                return false;

            // 群主不能被移除
            if (member.Role == MemberRole.Owner)
                throw new InvalidOperationException("无法移除群主");

            member.IsActive = false;

            // 发送系统消息
            var systemMessage = new ChatMessage
            {
                SenderId = operatorId,
                ChatGroupId = groupId,
                MessageType = MessageType.System,
                Content = $"{member.User.Username} 被移出群聊",
                SentAt = DateTime.UtcNow
            };
            _db.ChatMessages.Add(systemMessage);

            await _db.SaveChangesAsync();
            return true;
        }

        public async Task<bool> LeaveGroupAsync(int groupId, int userId)
        {
            var member = await _db.ChatGroupMembers
                .Include(m => m.User)
                .FirstOrDefaultAsync(m => m.ChatGroupId == groupId && m.UserId == userId && m.IsActive);

            if (member == null)
                return false;

            // 群主不能直接退出，需要先转让
            if (member.Role == MemberRole.Owner)
                throw new InvalidOperationException("群主需要先转让群组才能退出");

            member.IsActive = false;

            // 发送系统消息
            var systemMessage = new ChatMessage
            {
                SenderId = userId,
                ChatGroupId = groupId,
                MessageType = MessageType.System,
                Content = $"{member.User.Username} 退出了群聊",
                SentAt = DateTime.UtcNow
            };
            _db.ChatMessages.Add(systemMessage);

            await _db.SaveChangesAsync();
            return true;
        }

        public async Task<bool> UpdateGroupAsync(int groupId, int operatorId, string name, string? description)
        {
            // 检查操作者权限
            var operatorMember = await _db.ChatGroupMembers
                .FirstOrDefaultAsync(m => m.ChatGroupId == groupId && m.UserId == operatorId && m.IsActive);

            if (operatorMember == null || 
                (operatorMember.Role != MemberRole.Owner && operatorMember.Role != MemberRole.Admin))
                throw new UnauthorizedAccessException("无权限修改群组信息");

            var group = await _db.ChatGroups.FindAsync(groupId);
            if (group == null || !group.IsActive)
                return false;

            if (!string.IsNullOrWhiteSpace(name))
                group.Name = name;

            group.Description = description;
            group.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            return true;
        }
    }
}