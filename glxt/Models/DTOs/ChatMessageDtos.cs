namespace glxt.Models.DTOs
{
    public class SendMessageDto
    {
        public int? ReceiverId { get; set; }
        public int? ChatGroupId { get; set; }
        public string MessageType { get; set; } = "Text";
        public string Content { get; set; } = string.Empty;
        public string? AttachmentUrl { get; set; }
    }

    public class ChatMessageResponseDto
    {
        public int Id { get; set; }
        public int SenderId { get; set; }
        public string SenderUsername { get; set; } = string.Empty;
        public string? SenderFullName { get; set; }
        public int? ReceiverId { get; set; }
        public int? ChatGroupId { get; set; }
        public string MessageType { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? AttachmentUrl { get; set; }
        public DateTime SentAt { get; set; }
        public bool IsRead { get; set; }
    }
}