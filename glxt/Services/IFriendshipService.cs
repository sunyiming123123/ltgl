using glxt.Models.DTOs;

namespace glxt.Services
{
    public interface IFriendshipService
    {
        Task<FriendshipResponseDto> SendFriendRequestAsync(int requesterId, string addresseeUsername);
        Task<FriendshipResponseDto> HandleFriendRequestAsync(int userId, int friendshipId, bool accept);
        Task<List<FriendshipResponseDto>> GetFriendRequestsAsync(int userId);
        Task<List<FriendshipResponseDto>> GetFriendsAsync(int userId);
        Task<bool> RemoveFriendAsync(int userId, int friendId);
        Task<bool> BlockUserAsync(int userId, int blockedUserId);
    }
}