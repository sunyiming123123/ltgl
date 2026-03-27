# ========================================
# 快速验证部署脚本
# ========================================

$SERVER_IP = "139.224.245.244"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "验证部署状态..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 测试 API 可访问性
Write-Host "`n>>> 测试 API 连接..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://${SERVER_IP}:5000/health" -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ API 可访问 (状态码: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ API 无法访问: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "可能原因：1. 容器未启动 2. 防火墙未开放 3. 安全组未配置" -ForegroundColor Yellow
}

# 测试注册接口
Write-Host "`n>>> 测试用户注册..." -ForegroundColor Yellow
$registerData = @{
    username = "testuser_$(Get-Random -Maximum 10000)"
    email = "test_$(Get-Random -Maximum 10000)@example.com"
    password = "Test@123456"
    fullName = "Test User"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://${SERVER_IP}:5000/api/users/register" `
        -Method POST `
        -ContentType "application/json" `
        -Body $registerData `
        -TimeoutSec 10
    Write-Host "✅ 注册成功: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Green

    # 保存用户信息用于登录测试
    $global:testUsername = ($registerData | ConvertFrom-Json).username
    $global:testPassword = ($registerData | ConvertFrom-Json).password
} catch {
    Write-Host "❌ 注册失败: $($_.Exception.Message)" -ForegroundColor Red
}

# 测试登录接口
if ($global:testUsername) {
    Write-Host "`n>>> 测试用户登录..." -ForegroundColor Yellow
    $loginData = @{
        username = $global:testUsername
        password = $global:testPassword
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "http://${SERVER_IP}:5000/api/users/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body $loginData `
            -TimeoutSec 10
        Write-Host "✅ 登录成功！" -ForegroundColor Green
        Write-Host "Token: $($response.data.token.Substring(0, 50))..." -ForegroundColor Gray
    } catch {
        Write-Host "❌ 登录失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "验证完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
