using Microsoft.AspNetCore.Mvc;
using glxt.Models.DTOs;
using glxt.Services;
using glxt.Attributes;
using System.Security.Claims;

namespace glxt.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [JwtAuthorize]
    public class FriendshipController : ControllerBase
    {
        private readonly IFriendshipService _friendshipService;
        private readonly ILogger<FriendshipController> _logger;

        public FriendshipController(
            IFriendshipService friendshipService,
            ILogger<FriendshipController> logger)
        {
            _friendshipService = friendshipService;
            _logger = logger;
        }

        /// <summary>
        /// 获取当前用户ID
        /// </summary>
        private int GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                throw new UnauthorizedAccessException("无法获取用户信息");
            }
            return userId;
        }

        /// <summary>
        /// 发送好友请求
        /// </summary>
        [HttpPost("send-request")]
        public async Task<IActionResult> SendFriendRequest([FromBody] SendFriendRequestDto dto)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _friendshipService.SendFriendRequestAsync(userId, dto.Username);
                return Ok(new { success = true, data = result, message = "好友请求已发送" });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "发送好友请求失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 处理好友请求（接受或拒绝）
        /// </summary>
        [HttpPost("handle-request")]
        public async Task<IActionResult> HandleFriendRequest([FromBody] HandleFriendRequestDto dto)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _friendshipService.HandleFriendRequestAsync(
                    userId, dto.FriendshipId, dto.Accept);

                var message = dto.Accept ? "已接受好友请求" : "已拒绝好友请求";
                return Ok(new { success = true, data = result, message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Forbid();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "处理好友请求失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 获取好友请求列表（收到的待处理请求）
        /// </summary>
        [HttpGet("requests")]
        public async Task<IActionResult> GetFriendRequests()
        {
            try
            {
                var userId = GetCurrentUserId();
                var requests = await _friendshipService.GetFriendRequestsAsync(userId);
                return Ok(new { success = true, data = requests });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取好友请求失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 获取好友列表
        /// </summary>
        [HttpGet("friends")]
        public async Task<IActionResult> GetFriends()
        {
            try
            {
                var userId = GetCurrentUserId();
                var friends = await _friendshipService.GetFriendsAsync(userId);
                return Ok(new { success = true, data = friends });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取好友列表失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 删除好友
        /// </summary>
        [HttpDelete("remove/{friendId}")]
        public async Task<IActionResult> RemoveFriend(int friendId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _friendshipService.RemoveFriendAsync(userId, friendId);

                if (result)
                    return Ok(new { success = true, message = "已删除好友" });
                else
                    return NotFound(new { success = false, message = "好友关系不存在" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "删除好友失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 拉黑用户
        /// </summary>
        [HttpPost("block/{blockedUserId}")]
        public async Task<IActionResult> BlockUser(int blockedUserId)
        {
            try
            {
                var userId = GetCurrentUserId();
                await _friendshipService.BlockUserAsync(userId, blockedUserId);
                return Ok(new { success = true, message = "已拉黑用户" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "拉黑用户失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }
    }
}