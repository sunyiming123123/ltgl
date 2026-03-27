namespace glxt.Models.DTOs
{
    public class SendFriendRequestDto
    {
        public string Username { get; set; } = string.Empty;
    }

    public class HandleFriendRequestDto
    {
        public int FriendshipId { get; set; }
        public bool Accept { get; set; }
    }

    public class FriendshipResponseDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string? FullName { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public bool IsRequester { get; set; }
    }
}