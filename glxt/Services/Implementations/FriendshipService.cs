using glxt.Data;
using glxt.Models;
using glxt.Models.DTOs;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace glxt.Services.Implementations
{
    public class FriendshipService : IFriendshipService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<FriendshipService> _logger;

        public FriendshipService(ApplicationDbContext db, ILogger<FriendshipService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<FriendshipResponseDto> SendFriendRequestAsync(int requesterId, string addresseeUsername)
        {
            var addressee = await _db.Users
                .FirstOrDefaultAsync(u => u.Username == addresseeUsername);

            if (addressee == null)
                throw new InvalidOperationException("用户不存在");

            if (requesterId == addressee.Id)
                throw new InvalidOperationException("不能添加自己为好友");

            // 检查是否已存在好友关系
            var existing = await _db.Friendships
                .FirstOrDefaultAsync(f =>
                    (f.RequesterId == requesterId && f.AddresseeId == addressee.Id) ||
                    (f.RequesterId == addressee.Id && f.AddresseeId == requesterId));

            if (existing != null)
            {
                if (existing.Status == FriendshipStatus.Accepted)
                    throw new InvalidOperationException("已经是好友关系");
                if (existing.Status == FriendshipStatus.Pending)
                    throw new InvalidOperationException("好友请求已发送");
                if (existing.Status == FriendshipStatus.Blocked)
                    throw new InvalidOperationException("无法发送好友请求");
            }

            var friendship = new Friendship
            {
                RequesterId = requesterId,
                AddresseeId = addressee.Id,
                Status = FriendshipStatus.Pending,
                CreatedAt = DateTime.UtcNow
            };

            _db.Friendships.Add(friendship);
            await _db.SaveChangesAsync();

            return new FriendshipResponseDto
            {
                Id = friendship.Id,
                UserId = addressee.Id,
                Username = addressee.Username,
                FullName = addressee.FullName,
                Status = friendship.Status,
                CreatedAt = friendship.CreatedAt,
                IsRequester = true
            };
        }

        public async Task<FriendshipResponseDto> HandleFriendRequestAsync(int userId, int friendshipId, bool accept)
        {
            var friendship = await _db.Friendships
                .Include(f => f.Requester)
                .Include(f => f.Addressee)
                .FirstOrDefaultAsync(f => f.Id == friendshipId);

            if (friendship == null)
                throw new InvalidOperationException("好友请求不存在");

            if (friendship.AddresseeId != userId)
                throw new InvalidOperationException("无权操作此好友请求");

            if (friendship.Status != FriendshipStatus.Pending)
                throw new InvalidOperationException("该请求已被处理");

            friendship.Status = accept ? FriendshipStatus.Accepted : FriendshipStatus.Rejected;
            friendship.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return new FriendshipResponseDto
            {
                Id = friendship.Id,
                UserId = friendship.Requester.Id,
                Username = friendship.Requester.Username,
                FullName = friendship.Requester.FullName,
                Status = friendship.Status,
                CreatedAt = friendship.CreatedAt,
                IsRequester = false
            };
        }

        public async Task<List<FriendshipResponseDto>> GetFriendRequestsAsync(int userId)
        {
            var requests = await _db.Friendships
                .Include(f => f.Requester)
                .Include(f => f.Addressee)
                .Where(f => f.AddresseeId == userId && f.Status == FriendshipStatus.Pending)
                .OrderByDescending(f => f.CreatedAt)
                .ToListAsync();

            return requests.Select(f => new FriendshipResponseDto
            {
                Id = f.Id,
                UserId = f.Requester.Id,
                Username = f.Requester.Username,
                FullName = f.Requester.FullName,
                Status = f.Status,
                CreatedAt = f.CreatedAt,
                IsRequester = false
            }).ToList();
        }

        public async Task<List<FriendshipResponseDto>> GetFriendsAsync(int userId)
        {
            var friendships = await _db.Friendships
                .Include(f => f.Requester)
                .Include(f => f.Addressee)
                .Where(f => (f.RequesterId == userId || f.AddresseeId == userId) 
                    && f.Status == FriendshipStatus.Accepted)
                .ToListAsync();

            return friendships.Select(f =>
            {
                var isRequester = f.RequesterId == userId;
                var friend = isRequester ? f.Addressee : f.Requester;
                return new FriendshipResponseDto
                {
                    Id = f.Id,
                    UserId = friend.Id,
                    Username = friend.Username,
                    FullName = friend.FullName,
                    Status = f.Status,
                    CreatedAt = f.CreatedAt,
                    IsRequester = isRequester
                };
            }).ToList();
        }

        public async Task<bool> RemoveFriendAsync(int userId, int friendId)
        {
            var friendship = await _db.Friendships
                .FirstOrDefaultAsync(f =>
                    ((f.RequesterId == userId && f.AddresseeId == friendId) ||
                     (f.RequesterId == friendId && f.AddresseeId == userId)) &&
                    f.Status == FriendshipStatus.Accepted);

            if (friendship == null)
                return false;

            _db.Friendships.Remove(friendship);
            await _db.SaveChangesAsync();
            return true;
        }

        public async Task<bool> BlockUserAsync(int userId, int blockedUserId)
        {
            var friendship = await _db.Friendships
                .FirstOrDefaultAsync(f =>
                    (f.RequesterId == userId && f.AddresseeId == blockedUserId) ||
                    (f.RequesterId == blockedUserId && f.AddresseeId == userId));

            if (friendship != null)
            {
                friendship.Status = FriendshipStatus.Blocked;
                friendship.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                friendship = new Friendship
                {
                    RequesterId = userId,
                    AddresseeId = blockedUserId,
                    Status = FriendshipStatus.Blocked,
                    CreatedAt = DateTime.UtcNow
                };
                _db.Friendships.Add(friendship);
            }

            await _db.SaveChangesAsync();
            return true;
        }
    }
}