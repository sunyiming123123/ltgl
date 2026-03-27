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
    public class ChatGroupController : ControllerBase
    {
        private readonly IChatGroupService _chatGroupService;
        private readonly ILogger<ChatGroupController> _logger;

        public ChatGroupController(
            IChatGroupService chatGroupService,
            ILogger<ChatGroupController> logger)
        {
            _chatGroupService = chatGroupService;
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
        /// 创建群组
        /// </summary>
        [HttpPost("create")]
        public async Task<IActionResult> CreateGroup([FromBody] CreateChatGroupDto dto)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _chatGroupService.CreateGroupAsync(userId, dto);
                return Ok(new { success = true, data = result, message = "群组创建成功" });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "创建群组失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 获取群组详情
        /// </summary>
        [HttpGet("{groupId}")]
        public async Task<IActionResult> GetGroup(int groupId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _chatGroupService.GetGroupByIdAsync(groupId, userId);

                if (result == null)
                    return NotFound(new { success = false, message = "群组不存在或无权访问" });

                return Ok(new { success = true, data = result });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取群组信息失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 获取我的群组列表
        /// </summary>
        [HttpGet("my-groups")]
        public async Task<IActionResult> GetMyGroups()
        {
            try
            {
                var userId = GetCurrentUserId();
                var groups = await _chatGroupService.GetUserGroupsAsync(userId);
                return Ok(new { success = true, data = groups });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取群组列表失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 添加群成员
        /// </summary>
        [HttpPost("add-members")]
        public async Task<IActionResult> AddMembers([FromBody] AddGroupMembersDto dto)
        {
            try
            {
                var userId = GetCurrentUserId();
                await _chatGroupService.AddMembersAsync(dto.GroupId, userId, dto.Usernames);
                return Ok(new { success = true, message = "成员添加成功" });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Forbid();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "添加群成员失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 移除群成员
        /// </summary>
        [HttpDelete("remove-member")]
        public async Task<IActionResult> RemoveMember([FromQuery] int groupId, [FromQuery] int memberId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _chatGroupService.RemoveMemberAsync(groupId, userId, memberId);

                if (result)
                    return Ok(new { success = true, message = "成员已移除" });
                else
                    return NotFound(new { success = false, message = "成员不存在" });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Forbid();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "移除群成员失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 退出群组
        /// </summary>
        [HttpPost("leave/{groupId}")]
        public async Task<IActionResult> LeaveGroup(int groupId)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _chatGroupService.LeaveGroupAsync(groupId, userId);

                if (result)
                    return Ok(new { success = true, message = "已退出群组" });
                else
                    return NotFound(new { success = false, message = "群组不存在或不是成员" });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "退出群组失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }

        /// <summary>
        /// 更新群组信息
        /// </summary>
        [HttpPut("update/{groupId}")]
        public async Task<IActionResult> UpdateGroup(
            int groupId, 
            [FromBody] UpdateGroupDto dto)
        {
            try
            {
                var userId = GetCurrentUserId();
                var result = await _chatGroupService.UpdateGroupAsync(
                    groupId, userId, dto.Name, dto.Description);

                if (result)
                    return Ok(new { success = true, message = "群组信息已更新" });
                else
                    return NotFound(new { success = false, message = "群组不存在" });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Forbid();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "更新群组信息失败");
                return StatusCode(500, new { success = false, message = "服务器错误" });
            }
        }
    }

    // 补充 DTO
    public class UpdateGroupDto
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
    }
}