using glxt.Data;
using glxt.Models;
using glxt.Models.DTOs;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace glxt.Services.Implementations
{
    public class ChatMessageService : IChatMessageService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<ChatMessageService> _logger;

        public ChatMessageService(ApplicationDbContext db, ILogger<ChatMessageService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<ChatMessageResponseDto> SendMessageAsync(int senderId, SendMessageDto dto)
        {
            // 验证消息类型
            if (dto.ReceiverId == null && dto.ChatGroupId == null)
                throw new ArgumentException("必须指定接收者或群组");

            if (dto.ReceiverId != null && dto.ChatGroupId != null)
                throw new ArgumentException("不能同时指定接收者和群组");

            // 如果是私聊，检查是否是好友
            if (dto.ReceiverId != null)
            {
                var areFriends = await _db.Friendships
                    .AnyAsync(f =>
                        ((f.RequesterId == senderId && f.AddresseeId == dto.ReceiverId.Value) ||
                         (f.RequesterId == dto.ReceiverId.Value && f.AddresseeId == senderId)) &&
                        f.Status == FriendshipStatus.Accepted);

                if (!areFriends)
                    throw new InvalidOperationException("只能给好友发送消息");
            }

            // 如果是群聊，检查是否是群成员
            if (dto.ChatGroupId != null)
            {
                var isMember = await _db.ChatGroupMembers
                    .AnyAsync(m => m.ChatGroupId == dto.ChatGroupId.Value && 
                                   m.UserId == senderId && 
                                   m.IsActive);

                if (!isMember)
                    throw new InvalidOperationException("不是群成员，无法发送消息");
            }

            var message = new ChatMessage
            {
                SenderId = senderId,
                ReceiverId = dto.ReceiverId,
                ChatGroupId = dto.ChatGroupId,
                MessageType = dto.MessageType,
                Content = dto.Content,
                AttachmentUrl = dto.AttachmentUrl,
                SentAt = DateTime.UtcNow,
                IsRead = false
            };

            _db.ChatMessages.Add(message);
            await _db.SaveChangesAsync();

            // 加载发送者信息
            var sender = await _db.Users.FindAsync(senderId);

            return new ChatMessageResponseDto
            {
                Id = message.Id,
                SenderId = message.SenderId,
                SenderUsername = sender?.Username ?? "",
                SenderFullName = sender?.FullName,
                ReceiverId = message.ReceiverId,
                ChatGroupId = message.ChatGroupId,
                MessageType = message.MessageType,
                Content = message.Content,
                AttachmentUrl = message.AttachmentUrl,
                SentAt = message.SentAt,
                IsRead = message.IsRead
            };
        }

        public async Task<List<ChatMessageResponseDto>> GetPrivateMessagesAsync(
            int userId1, int userId2, int pageSize = 50, int page = 1)
        {
            // 检查是否是好友
            var areFriends = await _db.Friendships
                .AnyAsync(f =>
                    ((f.RequesterId == userId1 && f.AddresseeId == userId2) ||
                     (f.RequesterId == userId2 && f.AddresseeId == userId1)) &&
                    f.Status == FriendshipStatus.Accepted);

            if (!areFriends)
                throw new InvalidOperationException("不是好友关系");

            var messages = await _db.ChatMessages
                .Include(m => m.Sender)
                .Where(m =>
                    (m.SenderId == userId1 && m.ReceiverId == userId2) ||
                    (m.SenderId == userId2 && m.ReceiverId == userId1))
                .OrderByDescending(m => m.SentAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return messages.Select(m => new ChatMessageResponseDto
            {
                Id = m.Id,
                SenderId = m.SenderId,
                SenderUsername = m.Sender.Username,
                SenderFullName = m.Sender.FullName,
                ReceiverId = m.ReceiverId,
                ChatGroupId = m.ChatGroupId,
                MessageType = m.MessageType,
                Content = m.Content,
                AttachmentUrl = m.AttachmentUrl,
                SentAt = m.SentAt,
                IsRead = m.IsRead
            }).Reverse().ToList(); // 反转以按时间正序显示
        }

        public async Task<List<ChatMessageResponseDto>> GetGroupMessagesAsync(
            int groupId, int userId, int pageSize = 50, int page = 1)
        {
            // 检查是否是群成员
            var isMember = await _db.ChatGroupMembers
                .AnyAsync(m => m.ChatGroupId == groupId && m.UserId == userId && m.IsActive);

            if (!isMember)
                throw new InvalidOperationException("不是群成员");

            var messages = await _db.ChatMessages
                .Include(m => m.Sender)
                .Where(m => m.ChatGroupId == groupId)
                .OrderByDescending(m => m.SentAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return messages.Select(m => new ChatMessageResponseDto
            {
                Id = m.Id,
                SenderId = m.SenderId,
                SenderUsername = m.Sender.Username,
                SenderFullName = m.Sender.FullName,
                ReceiverId = m.ReceiverId,
                ChatGroupId = m.ChatGroupId,
                MessageType = m.MessageType,
                Content = m.Content,
                AttachmentUrl = m.AttachmentUrl,
                SentAt = m.SentAt,
                IsRead = m.IsRead
            }).Reverse().ToList();
        }

        public async Task<bool> MarkAsReadAsync(int messageId, int userId)
        {
            var message = await _db.ChatMessages
                .FirstOrDefaultAsync(m => m.Id == messageId && m.ReceiverId == userId);

            if (message == null)
                return false;

            if (!message.IsRead)
            {
                message.IsRead = true;
                message.ReadAt = DateTime.UtcNow;
                await _db.SaveChangesAsync();
            }

            return true;
        }

        public async Task<int> GetUnreadCountAsync(int userId)
        {
            return await _db.ChatMessages
                .Where(m => m.ReceiverId == userId && !m.IsRead)
                .CountAsync();
        }
    }
}