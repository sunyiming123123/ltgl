using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace glxt.Models
{
    /// <summary>
    /// 好友关系表
    /// </summary>
    public class Friendship
    {
        [Key]
        public int Id { get; set; }

        /// <summary>
        /// 发起请求的用户ID
        /// </summary>
        [Required]
        public int RequesterId { get; set; }

        /// <summary>
        /// 接收请求的用户ID
        /// </summary>
        [Required]
        public int AddresseeId { get; set; }

        /// <summary>
        /// 好友请求状态：Pending, Accepted, Rejected, Blocked
        /// </summary>
        [Required]
        [StringLength(20)]
        public string Status { get; set; } = FriendshipStatus.Pending;

        /// <summary>
        /// 请求发起时间
        /// </summary>
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// 状态更新时间
        /// </summary>
        public DateTime? UpdatedAt { get; set; }

        // 导航属性
        [ForeignKey(nameof(RequesterId))]
        public User Requester { get; set; } = null!;

        [ForeignKey(nameof(AddresseeId))]
        public User Addressee { get; set; } = null!;
    }

    public static class FriendshipStatus
    {
        public const string Pending = "Pending";
        public const string Accepted = "Accepted";
        public const string Rejected = "Rejected";
        public const string Blocked = "Blocked";
    }
}