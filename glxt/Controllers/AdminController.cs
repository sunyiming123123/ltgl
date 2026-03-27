using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using glxt.Data;
using glxt.Models;
using Microsoft.EntityFrameworkCore;
using BCryptLib = BCrypt.Net.BCrypt;

namespace glxt.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous] // 临时允许，生产环境应该保护此端点
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<AdminController> _logger;

        public AdminController(ApplicationDbContext db, ILogger<AdminController> logger)
        {
            _db = db;
            _logger = logger;
        }

        /// <summary>
        /// 检查所有用户的密码哈希格式
        /// </summary>
        [HttpGet("check-password-hashes")]
        public async Task<IActionResult> CheckPasswordHashes()
        {
            var users = await _db.Users.ToListAsync();
            var results = users.Select(u => new
            {
                u.Id,
                u.Username,
                u.Email,
                u.IsActive,
                PasswordHashLength = u.PasswordHash?.Length ?? 0,
                IsBCryptFormat = u.PasswordHash?.StartsWith("$2") ?? false,
                HashPreview = u.PasswordHash?.Length > 20 
                    ? u.PasswordHash.Substring(0, 20) + "..." 
                    : u.PasswordHash
            }).ToList();

            return Ok(new
            {
                success = true,
                totalUsers = users.Count,
                data = results
            });
        }

        /// <summary>
        /// 创建测试用户（带正确的 BCrypt 哈希）
        /// </summary>
        [HttpPost("create-test-user")]
        public async Task<IActionResult> CreateTestUser([FromBody] CreateTestUserRequest request)
        {
            try
            {
                // 检查用户是否已存在
                var exists = await _db.Users.AnyAsync(u => u.Username == request.Username || u.Email == request.Email);
                if (exists)
                {
                    return BadRequest(new { success = false, message = "用户名或邮箱已存在" });
                }

                // 生成 BCrypt 哈希
                var hash = BCryptLib.HashPassword(request.Password);
                _logger.LogInformation("Created BCrypt hash for test user. Hash length: {Length}, Starts with $2: {Valid}",
                    hash.Length, hash.StartsWith("$2"));

                var user = new User
                {
                    Username = request.Username,
                    Email = request.Email,
                    PasswordHash = hash,
                    FullName = request.FullName ?? "Test User",
                    CreatedAt = DateTime.UtcNow,
                    IsActive = true
                };

                _db.Users.Add(user);
                await _db.SaveChangesAsync();

                return Ok(new
                {
                    success = true,
                    message = "测试用户创建成功",
                    data = new
                    {
                        user.Id,
                        user.Username,
                        user.Email,
                        HashLength = hash.Length,
                        IsBCryptFormat = hash.StartsWith("$2")
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create test user");
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        /// <summary>
        /// 修复指定用户的密码哈希（将明文密码转换为 BCrypt 哈希）
        /// 警告：仅用于开发/测试环境
        /// </summary>
        [HttpPost("fix-user-password/{userId}")]
        public async Task<IActionResult> FixUserPassword(int userId, [FromBody] FixPasswordRequest request)
        {
            var user = await _db.Users.FindAsync(userId);
            if (user == null)
            {
                return NotFound(new { success = false, message = "用户不存在" });
            }

            var oldHash = user.PasswordHash;
            var newHash = BCryptLib.HashPassword(request.NewPassword);
            user.PasswordHash = newHash;
            user.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = "密码哈希已修复",
                data = new
                {
                    userId = user.Id,
                    username = user.Username,
                    oldHashPreview = oldHash?.Length > 20 ? oldHash.Substring(0, 20) + "..." : oldHash,
                    oldHashLength = oldHash?.Length ?? 0,
                    newHashLength = newHash.Length,
                    isBCryptFormat = newHash.StartsWith("$2")
                }
            });
        }

        public class CreateTestUserRequest
        {
            public string Username { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
            public string? FullName { get; set; }
        }

        public class FixPasswordRequest
        {
            public string NewPassword { get; set; } = string.Empty;
        }
    }
}
