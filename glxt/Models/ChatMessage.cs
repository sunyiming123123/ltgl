using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace glxt.Models
{
    /// <summary>
    /// 聊天消息（支持私聊和群聊）
    /// </summary>
    public class ChatMessage
    {
        [Key]
        public int Id { get; set; }

        /// <summary>
        /// 发送者ID
        /// </summary>
        [Required]
        public int SenderId { get; set; }

        /// <summary>
        /// 接收者ID（私聊时使用，群聊时为null）
        /// </summary>
        public int? ReceiverId { get; set; }

        /// <summary>
        /// 群组ID（群聊时使用，私聊时为null）
        /// </summary>
        public int? ChatGroupId { get; set; }

        /// <summary>
        /// 消息类型：Text, Image, File, System
        /// </summary>
        [Required]
        [StringLength(20)]
        public string MessageType { get; set; } = glxt.Models.MessageType.Text;

        /// <summary>
        /// 消息内容
        /// </summary>
        [Required]
        public string Content { get; set; } = string.Empty;

        /// <summary>
        /// 附件URL（图片、文件等）
        /// </summary>
        [StringLength(500)]
        public string? AttachmentUrl { get; set; }

        /// <summary>
        /// 发送时间
        /// </summary>
        public DateTime SentAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// 是否已读（私聊时使用）
        /// </summary>
        public bool IsRead { get; set; } = false;

        /// <summary>
        /// 已读时间
        /// </summary>
        public DateTime? ReadAt { get; set; }

        // 导航属性
        [ForeignKey(nameof(SenderId))]
        public User Sender { get; set; } = null!;

        [ForeignKey(nameof(ReceiverId))]
        public User? Receiver { get; set; }

        [ForeignKey(nameof(ChatGroupId))]
        public ChatGroup? ChatGroup { get; set; }
    }

    public static class MessageType
    {
        public const string Text = "Text";
        public const string Image = "Image";
        public const string File = "File";
        public const string System = "System";
    }
}