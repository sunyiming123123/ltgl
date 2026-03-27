using glxt.Models.DTOs;

namespace glxt.Services
{
    public interface IChatMessageService
    {
        Task<ChatMessageResponseDto> SendMessageAsync(int senderId, SendMessageDto dto);
        Task<List<ChatMessageResponseDto>> GetPrivateMessagesAsync(int userId1, int userId2, int pageSize = 50, int page = 1);
        Task<List<ChatMessageResponseDto>> GetGroupMessagesAsync(int groupId, int userId, int pageSize = 50, int page = 1);
        Task<bool> MarkAsReadAsync(int messageId, int userId);
        Task<int> GetUnreadCountAsync(int userId);
    }
}