namespace glxt.Models.DTOs
{
    public class CreateChatGroupDto
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public List<string> MemberUsernames { get; set; } = new List<string>();
    }

    public class AddGroupMembersDto
    {
        public int GroupId { get; set; }
        public List<string> Usernames { get; set; } = new List<string>();
    }

    public class ChatGroupResponseDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? AvatarUrl { get; set; }
        public int CreatorId { get; set; }
        public DateTime CreatedAt { get; set; }
        public int MemberCount { get; set; }
        public List<GroupMemberDto> Members { get; set; } = new List<GroupMemberDto>();
    }

    public class GroupMemberDto
    {
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string? FullName { get; set; }
        public string Role { get; set; } = string.Empty;
        public DateTime JoinedAt { get; set; }
    }
}