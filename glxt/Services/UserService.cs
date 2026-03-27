using glxt.Data;
using glxt.Models;
using glxt.Models.DTOs;
using glxt.Services; // 需要引用接口所在命名空间
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BCryptLib = BCrypt.Net.BCrypt; // 更改别名以避免冲突

namespace glxt.Services.Implementations
{
    // 将实现移至子命名空间以避免与同一命名空间中另一个同名类型冲突（CS0101）
    public class UserService : IUserService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<UserService> _logger;
        private readonly IJwtService _jwtService;

        public UserService(ApplicationDbContext db, ILogger<UserService> logger, IJwtService jwtService)
        {
            _db = db;
            _logger = logger;
            _jwtService = jwtService;
        }

        public async Task<User?> AuthenticateAsync(string usernameOrEmail, string password)
        {
            if (string.IsNullOrWhiteSpace(usernameOrEmail) || string.IsNullOrEmpty(password))
            {
                _logger.LogWarning("Login attempt with empty username or password");
                return null;
            }

            var user = await _db.Users
                .Where(u => u.Username == usernameOrEmail || u.Email == usernameOrEmail)
                .FirstOrDefaultAsync();

            if (user == null)
            {
                _logger.LogWarning("User not found: {UsernameOrEmail}", usernameOrEmail);
                return null;
            }

            _logger.LogInformation("User found: {Username}, IsActive: {IsActive}, PasswordHash length: {HashLength}, Starts with $2: {IsBCrypt}",
                user.Username, user.IsActive, user.PasswordHash?.Length ?? 0, user.PasswordHash?.StartsWith("$2") ?? false);

            try
            {
                var verified = BCryptLib.Verify(password, user.PasswordHash);
                _logger.LogInformation("BCrypt verification result for {Username}: {Verified}", user.Username, verified);
                return verified ? user : null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "BCrypt verify EXCEPTION for user {UsernameOrEmail}. PasswordHash: '{HashPreview}'",
                    usernameOrEmail, user.PasswordHash?.Substring(0, Math.Min(20, user.PasswordHash?.Length ?? 0)));
                return null;
            }
        }

        public async Task<User> CreateAsync(string username, string email, string password, string? fullName = null)
        {
            if (string.IsNullOrWhiteSpace(username))
                throw new ArgumentException("username is required", nameof(username));
            if (string.IsNullOrWhiteSpace(email))
                throw new ArgumentException("email is required", nameof(email));
            if (string.IsNullOrEmpty(password))
                throw new ArgumentException("password is required", nameof(password));

            // 预检查，避免因为唯一索引导致的 DbUpdateException 在 SaveChanges 时抛出
            var exists = await _db.Users.AnyAsync(u => u.Username == username || u.Email == email);
            if (exists)
                throw new InvalidOperationException("用户名或邮箱已存在");

            var hash = BCryptLib.HashPassword(password);

            var user = new User
            {
                Username = username,
                Email = email,
                PasswordHash = hash,
                FullName = fullName,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _db.Users.Add(user);

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateException dbEx)
            {
                _logger.LogError(dbEx, "数据库保存用户失败");
                // 根据需要可以解析 InnerException 来判断是否唯一索引冲突
                throw new InvalidOperationException("保存用户时发生错误", dbEx);
            }

            return user;
        }

        public Task<User?> GetByIdAsync(int id)
        {
            return _db.Users.FirstOrDefaultAsync(u => u.Id == id);
        }

        public Task<bool> ExistsByUsernameOrEmailAsync(string username, string email)
        {
            return _db.Users.AnyAsync(u => u.Username == username || u.Email == email);
        }

        // 辅助方法：将 User 实体映射为 UserResponseDto
        private UserResponseDto MapToDto(User user)
        {
            return new UserResponseDto
            {
                Id = user.Id,
                Username = user.Username,
                Email = user.Email,
                FullName = user.FullName,
                CreatedAt = user.CreatedAt,
                IsActive = user.IsActive
            };
        }

        // 实现接口方法

        async Task<UserResponseDto> IUserService.RegisterAsync(RegisterUserDto registerDto)
        {
            // 使用现有的 CreateAsync 方法创建用户
            var user = await CreateAsync(
                registerDto.Username,
                registerDto.Email,
                registerDto.Password,
                registerDto.FullName
            );

            return MapToDto(user);
        }

        async Task<LoginResponseDto> IUserService.LoginAsync(LoginUserDto loginDto)
        {
            // 使用现有的 AuthenticateAsync 方法验证用户
            var user = await AuthenticateAsync(loginDto.Username, loginDto.Password);

            if (user == null)
            {
                throw new UnauthorizedAccessException("用户名或密码错误");
            }

            if (!user.IsActive)
            {
                throw new UnauthorizedAccessException("账户已被禁用");
            }

            // 生成 JWT 令牌
            var token = _jwtService.GenerateToken(user);

            return new LoginResponseDto
            {
                Token = token,
                User = MapToDto(user)
            };
        }

        async Task<List<UserResponseDto>> IUserService.GetUsersAsync()
        {
            var users = await _db.Users
                .OrderByDescending(u => u.CreatedAt)
                .ToListAsync();

            return users.Select(MapToDto).ToList();
        }

        async Task<UserResponseDto?> IUserService.GetUserByIdAsync(int id)
        {
            var user = await GetByIdAsync(id);
            return user == null ? null : MapToDto(user);
        }

        async Task<UserResponseDto?> IUserService.GetUserByUsernameAsync(string username)
        {
            var user = await _db.Users
                .FirstOrDefaultAsync(u => u.Username == username);

            return user == null ? null : MapToDto(user);
        }
    }
}