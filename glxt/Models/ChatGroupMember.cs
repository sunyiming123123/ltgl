using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace glxt.Models
{
    /// <summary>
    /// 群组成员关系表
    /// </summary>
    public class ChatGroupMember
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int ChatGroupId { get; set; }

        [Required]
        public int UserId { get; set; }

        /// <summary>
        /// 成员角色：Owner, Admin, Member
        /// </summary>
        [Required]
        [StringLength(20)]
        public string Role { get; set; } = MemberRole.Member;

        /// <summary>
        /// 加入时间
        /// </summary>
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// 是否活跃（用于软删除）
        /// </summary>
        public bool IsActive { get; set; } = true;

        // 导航属性
        [ForeignKey(nameof(ChatGroupId))]
        public ChatGroup ChatGroup { get; set; } = null!;

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;
    }

    public static class MemberRole
    {
        public const string Owner = "Owner";
        public const string Admin = "Admin";
        public const string Member = "Member";
    }
}