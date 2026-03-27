using glxt.Models;

namespace glxt.Services.Abstractions
{
    public interface IUserService
    {
        Task<User?> AuthenticateAsync(string usernameOrEmail, string password);
        Task<User> CreateAsync(string username, string email, string password, string? fullName = null);
        Task<User?> GetByIdAsync(int id);
        Task<bool> ExistsByUsernameOrEmailAsync(string username, string email);
    }
}