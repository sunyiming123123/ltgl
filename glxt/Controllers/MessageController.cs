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
    public class MessageController : ControllerBase
    {
        private readonly IChatMessageService _messageService;
        private readonly ILogger<MessageController> _logger;

        public MessageController(
            IChatMessageService messageService,
            ILogger<MessageController> logger)
        {
            _messageService = messageService;
            _logger = logger;
        }

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
        /// 发送消息（私聊或群聊）
        /// </summary>
        [HttpPost("send")]
        public async Task<IActionResult> SendMessage([FromBody] SendMessageDto dto)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _messageService.SendMessageAsync(userId, dto);
                return Ok(new { success = true, data = result, message = "消息发送成功" });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "发送消息失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 获取私聊消息记录
        /// </summary>
        [HttpGet("private/{friendId}")]
        public async Task<IActionResult> GetPrivateMessages(
            int friendId,
            [FromQuery] int pageSize = 50,
            [FromQuery] int page = 1)
        {
            try
            {
                var userId = GetCurrentUserId();
                var messages = await _messageService.GetPrivateMessagesAsync(
                    userId, friendId, pageSize, page);

                return Ok(new
                {
                    success = true,
                    data = messages,
                    pagination = new
                    {
                        page,
                        pageSize,
                        total = messages.Count
                    }
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取私聊消息失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 获取群聊消息记录
        /// </summary>
        [HttpGet("group/{groupId}")]
        public async Task<IActionResult> GetGroupMessages(
            int groupId,
            [FromQuery] int pageSize = 50,
            [FromQuery] int page = 1)
        {
            try
            {
                var userId = GetCurrentUserId();
                var messages = await _messageService.GetGroupMessagesAsync(
                    groupId, userId, pageSize, page);

                return Ok(new
                {
                    success = true,
                    data = messages,
                    pagination = new
                    {
                        page,
                        pageSize,
                        total = messages.Count
                    }
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取群聊消息失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 标记消息为已读
        /// </summary>
        [HttpPut("mark-read/{messageId}")]
        public async Task<IActionResult> MarkAsRead(int messageId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _messageService.MarkAsReadAsync(messageId, userId);

                if (result)
                    return Ok(new { success = true, message = "已标记为已读" });
                else
                    return NotFound(new { success = false, message = "消息不存在" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "标记消息已读失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 获取未读消息数量
        /// </summary>
        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            try
            {
                var userId = GetCurrentUserId();
                var count = await _messageService.GetUnreadCountAsync(userId);
                return Ok(new { success = true, data = new { unreadCount = count } });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取未读消息数失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }
    }
}