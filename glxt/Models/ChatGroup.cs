using System.ComponentModel.DataAnnotations;

namespace glxt.Models
{
    /// <summary>
    /// 聊天群组
    /// </summary>
    public class ChatGroup
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [StringLength(500)]
        public string? Description { get; set; }

        /// <summary>
        /// 群组创建者ID
        /// </summary>
        [Required]
        public int CreatorId { get; set; }

        /// <summary>
        /// 群组头像URL
        /// </summary>
        [StringLength(500)]
        public string? AvatarUrl { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        /// <summary>
        /// 是否激活
        /// </summary>
        public bool IsActive { get; set; } = true;

        // 导航属性
        public User Creator { get; set; } = null!;
        public ICollection<ChatGroupMember> Members { get; set; } = new List<ChatGroupMember>();
        public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
    }
}