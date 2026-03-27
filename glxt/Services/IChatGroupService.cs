using glxt.Models.DTOs;

namespace glxt.Services
{
    public interface IChatGroupService
    {
        Task<ChatGroupResponseDto> CreateGroupAsync(int creatorId, CreateChatGroupDto dto);
        Task<ChatGroupResponseDto?> GetGroupByIdAsync(int groupId, int userId);
        Task<List<ChatGroupResponseDto>> GetUserGroupsAsync(int userId);
        Task<bool> AddMembersAsync(int groupId, int operatorId, List<string> usernames);
        Task<bool> RemoveMemberAsync(int groupId, int operatorId, int memberId);
        Task<bool> LeaveGroupAsync(int groupId, int userId);
        Task<bool> UpdateGroupAsync(int groupId, int operatorId, string name, string? description);
    }
}