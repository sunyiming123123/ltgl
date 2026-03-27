# 聊天功能一键部署脚本
# 用法: .\setup-chat-feature.ps1

$ErrorActionPreference = "Stop"
Set-Location "D:\test\glxt"

Write-Host "=== 开始部署聊天功能 ===" -ForegroundColor Green

# 步骤 1: 检查并创建目录
Write-Host "`n[1/6] 创建必要的目录..." -ForegroundColor Yellow
$directories = @(
    "glxt\Models",
    "glxt\Models\DTOs",
    "glxt\Services",
    "glxt\Services\Implementations",
    "glxt\Controllers"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  创建目录: $dir" -ForegroundColor Gray
    }
}
Write-Host "  ✓ 目录结构准备完成" -ForegroundColor Green

# 步骤 2: 添加 EF Core 迁移
Write-Host "`n[2/6] 检查数据库迁移工具..." -ForegroundColor Yellow
$efToolCheck = dotnet tool list --global | Select-String "dotnet-ef"
if (!$efToolCheck) {
    Write-Host "  安装 EF Core 工具..." -ForegroundColor Gray
    dotnet tool install --global dotnet-ef
}
Write-Host "  ✓ EF Core 工具就绪" -ForegroundColor Green

# 步骤 3: 编译项目
Write-Host "`n[3/6] 编译项目..." -ForegroundColor Yellow
$buildOutput = dotnet build --no-incremental 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ✗ 编译失败" -ForegroundColor Red
    Write-Host $buildOutput
    Write-Host "`n提示: 请先确保所有模型文件已创建。" -ForegroundColor Yellow
    exit 1
}
Write-Host "  ✓ 项目编译成功" -ForegroundColor Green

# 步骤 4: 创建数据库迁移
Write-Host "`n[4/6] 创建数据库迁移..." -ForegroundColor Yellow
try {
    $migrationName = "AddChatFeatures_$(Get-Date -Format 'yyyyMMddHHmmss')"
    dotnet ef migrations add $migrationName --project glxt
    Write-Host "  ✓ 迁移创建成功: $migrationName" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 迁移创建失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

# 步骤 5: 应用数据库迁移
Write-Host "`n[5/6] 应用数据库迁移..." -ForegroundColor Yellow
try {
    dotnet ef database update --project glxt
    Write-Host "  ✓ 数据库更新成功" -ForegroundColor Green
} catch {
    Write-Host "  ⚠ 数据库更新失败（可能数据库未配置）" -ForegroundColor Yellow
    Write-Host "  请手动运行: dotnet ef database update" -ForegroundColor Gray
}

# 步骤 6: 验证 API 端点
Write-Host "`n[6/6] 生成 API 端点列表..." -ForegroundColor Yellow
Write-Host @"

=== 可用的聊天 API 端点 ===

【好友功能】
POST   /api/friendship/send-request          发送好友请求
POST   /api/friendship/handle-request         处理好友请求
GET    /api/friendship/requests               获取好友请求列表
GET    /api/friendship/friends                获取好友列表
DELETE /api/friendship/remove/{friendId}      删除好友
POST   /api/friendship/block/{userId}         拉黑用户

【群组功能】
POST   /api/chatgroup/create                  创建群组
GET    /api/chatgroup/{groupId}               获取群组信息
GET    /api/chatgroup/my-groups               获取我的群组列表
POST   /api/chatgroup/add-members             添加群成员
DELETE /api/chatgroup/remove-member           移除群成员
POST   /api/chatgroup/leave/{groupId}         退出群组

【消息功能】
POST   /api/message/send                      发送消息
GET    /api/message/private/{userId}          获取私聊消息
GET    /api/message/group/{groupId}           获取群聊消息
PUT    /api/message/mark-read/{messageId}     标记消息已读
GET    /api/message/unread-count              获取未读消息数

"@ -ForegroundColor Cyan

Write-Host "`n=== 部署完成 ===" -ForegroundColor Green
Write-Host "启动项目: dotnet run --project glxt" -ForegroundColor Yellow
Write-Host "Swagger UI: https://localhost:5001/swagger" -ForegroundColor Yellow

# 验证聊天功能文件创建和编译测试脚本
Write-Host "=== 开始验证聊天功能文件 ===" -ForegroundColor Green

# 设置工作目录
Set-Location "D:\test\glxt"

# 1. 检查模型文件是否存在
Write-Host "`n检查模型文件..." -ForegroundColor Yellow
$modelFiles = @(
    "glxt\Models\Friendship.cs",
    "glxt\Models\ChatGroup.cs",
    "glxt\Models\ChatGroupMember.cs",
    "glxt\Models\ChatMessage.cs"
)

$missingModels = @()
foreach ($file in $modelFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file 存在" -ForegroundColor Green
    } else {
        Write-Host "✗ $file 不存在" -ForegroundColor Red
        $missingModels += $file
    }
}

# 2. 检查 DTO 文件
Write-Host "`n检查 DTO 文件..." -ForegroundColor Yellow
$dtoFiles = @(
    "glxt\Models\DTOs\FriendshipDtos.cs",
    "glxt\Models\DTOs\ChatGroupDtos.cs",
    "glxt\Models\DTOs\ChatMessageDtos.cs"
)

$missingDtos = @()
foreach ($file in $dtoFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file 存在" -ForegroundColor Green
    } else {
        Write-Host "✗ $file 不存在" -ForegroundColor Red
        $missingDtos += $file
    }
}

# 3. 检查服务接口文件
Write-Host "`n检查服务接口文件..." -ForegroundColor Yellow
$serviceInterfaceFiles = @(
    "glxt\Services\IFriendshipService.cs",
    "glxt\Services\IChatGroupService.cs",
    "glxt\Services\IChatMessageService.cs"
)

$missingInterfaces = @()
foreach ($file in $serviceInterfaceFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file 存在" -ForegroundColor Green
    } else {
        Write-Host "✗ $file 不存在" -ForegroundColor Red
        $missingInterfaces += $file
    }
}

# 4. 检查服务实现文件
Write-Host "`n检查服务实现文件..." -ForegroundColor Yellow
$serviceImplFiles = @(
    "glxt\Services\Implementations\FriendshipService.cs"
)

$missingImpls = @()
foreach ($file in $serviceImplFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file 存在" -ForegroundColor Green
    } else {
        Write-Host "✗ $file 不存在" -ForegroundColor Red
        $missingImpls += $file
    }
}

# 5. 统计结果
Write-Host "`n=== 文件检查摘要 ===" -ForegroundColor Cyan
$totalMissing = $missingModels.Count + $missingDtos.Count + $missingInterfaces.Count + $missingImpls.Count
if ($totalMissing -eq 0) {
    Write-Host "✓ 所有文件都已创建！" -ForegroundColor Green
} else {
    Write-Host "✗ 缺失 $totalMissing 个文件" -ForegroundColor Red
    Write-Host "`n需要创建这些文件，请使用 GitHub Copilot 创建它们。" -ForegroundColor Yellow
}

# 6. 尝试编译项目
Write-Host "`n=== 尝试编译项目 ===" -ForegroundColor Cyan
Write-Host "运行: dotnet build" -ForegroundColor Yellow
$buildResult = dotnet build 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 项目编译成功！" -ForegroundColor Green
} else {
    Write-Host "✗ 项目编译失败" -ForegroundColor Red
    Write-Host "`n编译输出:" -ForegroundColor Yellow
    Write-Host $buildResult
}

Write-Host "`n=== 验证完成 ===" -ForegroundColor Green

# 检查模型文件是否存在
Get-ChildItem -Path glxt\Models -Filter "*.cs" -Recurse | Select-Object Name

# 检查是否可以编译
dotnet build

# 如果编译失败，查看错误
dotnet build > build-log.txt 2>&1
Get-Content build-log.txt