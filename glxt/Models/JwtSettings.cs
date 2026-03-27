using System.ComponentModel.DataAnnotations;

namespace glxt.Models
{
    public class JwtSettings
    {
        [Required]
        [MinLength(32)]
        public string Secret { get; set; } = string.Empty;

        [Required]
        public string Issuer { get; set; } = string.Empty;

        [Required]
        public string Audience { get; set; } = string.Empty;

        [Range(1, 1440)]
        public int ExpireMinutes { get; set; } = 60;
    }
}