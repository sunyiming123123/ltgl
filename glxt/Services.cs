using Microsoft.EntityFrameworkCore;
using glxt.Data;
using glxt.Models;
using glxt.Models.DTOs;
using System.Security.Cryptography;
using System.Text;

namespace glxt.Services
{
    public interface IUserService
    {
        Task<UserResponseDto> RegisterAsync(RegisterUserDto registerDto);
        Task<LoginResponseDto> LoginAsync(LoginUserDto loginDto);
        Task<List<UserResponseDto>> GetUsersAsync();
        Task<UserResponseDto?> GetUserByIdAsync(int id);
        Task<UserResponseDto?> GetUserByUsernameAsync(string username);
    }

    public class UserService : IUserService
    {
        private readonly ApplicationDbContext _context;
private readonly IJwtService _jwtService;

public UserService(ApplicationDbContext context, IJwtService jwtService)
{
    _context = context;
    _jwtService = jwtService;
}

        public async Task<UserResponseDto> RegisterAsync(RegisterUserDto registerDto)
        {
            // 检查用户名是否已存在
            if (await _context.Users.AnyAsync(u => u.Username == registerDto.Username))
                throw new Exception("用户名已存在");

            // 检查邮箱是否已存在
            if (await _context.Users.AnyAsync(u => u.Email == registerDto.Email))
                throw new Exception("邮箱已存在");

            // 创建用户
            var user = new User
            {
                Username = registerDto.Username,
                Email = registerDto.Email,
                FullName = registerDto.FullName,
                PasswordHash = HashPassword(registerDto.Password),
                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return MapToUserResponseDto(user);
        }

        public async Task<LoginResponseDto> LoginAsync(LoginUserDto loginDto)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Username == loginDto.Username && u.IsActive);

            if (user == null || !VerifyPassword(loginDto.Password, user.PasswordHash))
                throw new Exception("用户名或密码错误");

            // 生成 JWT token
            var token = _jwtService.GenerateToken(user);

            return new LoginResponseDto
            {
                Token = token,
                User = MapToUserResponseDto(user)
            };
        }

        public async Task<List<UserResponseDto>> GetUsersAsync()
        {
            var users = await _context.Users
                .Where(u => u.IsActive)
                .OrderBy(u => u.Id)
                .ToListAsync();

            return users.Select(MapToUserResponseDto).ToList();
        }

        public async Task<UserResponseDto?> GetUserByIdAsync(int id)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == id && u.IsActive);

            return user != null ? MapToUserResponseDto(user) : null;
        }

        public async Task<UserResponseDto?> GetUserByUsernameAsync(string username)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Username == username && u.IsActive);

            return user != null ? MapToUserResponseDto(user) : null;
        }

        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var bytes = Encoding.UTF8.GetBytes(password);
            var hash = sha256.ComputeHash(bytes);
            return Convert.ToBase64String(hash);
        }

        private bool VerifyPassword(string password, string passwordHash)
        {
            return HashPassword(password) == passwordHash;
        }

        private UserResponseDto MapToUserResponseDto(User user)
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
    }
}