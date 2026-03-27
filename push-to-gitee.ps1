# Gitee 推送辅助脚本
# 此脚本帮助您配置个人访问令牌并推送代码

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   Gitee 推送配置向导" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "您的仓库信息:" -ForegroundColor Yellow
Write-Host "  用户名: 19145960820" -ForegroundColor White
Write-Host "  仓库: GLXT" -ForegroundColor White
Write-Host "  地址: https://gitee.com/19145960820/GLXT" -ForegroundColor White
Write-Host ""

# 检查仓库是否存在
Write-Host "检查仓库状态..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://gitee.com/19145960820/GLXT" -UseBasicParsing -Method Head -ErrorAction Stop
    Write-Host "  仓库已存在" -ForegroundColor Green
    $repoExists = $true
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "  仓库不存在" -ForegroundColor Red
        Write-Host ""
        Write-Host "请先创建仓库:" -ForegroundColor Yellow
        Write-Host "  1. 访问: https://gitee.com/projects/new" -ForegroundColor Cyan
        Write-Host "  2. 仓库名称: GLXT" -ForegroundColor White
        Write-Host "  3. 不要勾选 '使用 Readme 文件初始化'" -ForegroundColor Red
        Write-Host "  4. 点击创建" -ForegroundColor White
        Write-Host ""
        $create = Read-Host "仓库创建完成后，按 Enter 继续"
        $repoExists = $true
    } else {
        Write-Host "  无法检查仓库状态（可能是网络问题）" -ForegroundColor Yellow
        $repoExists = $true
    }
}

if (-not $repoExists) {
    exit 1
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   配置认证方式" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "选择认证方式:" -ForegroundColor Yellow
Write-Host "1. 使用个人访问令牌 (推荐)" -ForegroundColor Cyan
Write-Host "2. 使用 SSH 密钥" -ForegroundColor White
Write-Host "3. 使用用户名和密码 (不推荐，可能失败)" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "请选择 (1-3)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "使用个人访问令牌" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "步骤 1: 生成令牌" -ForegroundColor Yellow
        Write-Host "  1. 打开浏览器访问:" -ForegroundColor White
        Write-Host "     https://gitee.com/profile/personal_access_tokens" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  2. 点击 '生成新令牌'" -ForegroundColor White
        Write-Host "  3. 令牌描述: GLXT Deploy" -ForegroundColor White
        Write-Host "  4. 权限范围: 勾选 'projects'" -ForegroundColor White
        Write-Host "  5. 点击 '提交'" -ForegroundColor White
        Write-Host "  6. 复制生成的令牌 (只显示一次!)" -ForegroundColor Red
        Write-Host ""

        Read-Host "令牌生成完成后，按 Enter 继续"

        Write-Host ""
        $token = Read-Host "请粘贴您的个人访问令牌" -AsSecureString
        $tokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
        )

        # 使用令牌配置 URL
        $urlWithToken = "https://19145960820:$tokenPlain@gitee.com/19145960820/GLXT.git"

        Write-Host ""
        Write-Host "配置远程仓库..." -ForegroundColor Yellow
        git remote set-url origin $urlWithToken

        Write-Host ""
        Write-Host "推送代码..." -ForegroundColor Yellow
        git push -u origin master

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "推送成功!" -ForegroundColor Green

            # 移除 URL 中的令牌（安全考虑）
            Write-Host ""
            Write-Host "清理敏感信息..." -ForegroundColor Gray
            git remote set-url origin "https://gitee.com/19145960820/GLXT.git"

            # 保存凭证
            Write-Host "保存凭证到凭证管理器..." -ForegroundColor Gray
            git config --global credential.helper manager
        } else {
            Write-Host ""
            Write-Host "推送失败!" -ForegroundColor Red
            Write-Host "可能的原因:" -ForegroundColor Yellow
            Write-Host "  1. 令牌无效或权限不足" -ForegroundColor White
            Write-Host "  2. 令牌已过期" -ForegroundColor White
            Write-Host "  3. 网络连接问题" -ForegroundColor White
        }
    }

    "2" {
        Write-Host ""
        Write-Host "配置 SSH 密钥" -ForegroundColor Cyan
        Write-Host ""

        # 检查是否已有密钥
        if (Test-Path "$env:USERPROFILE\.ssh\id_rsa.pub") {
            Write-Host "检测到已有 SSH 密钥" -ForegroundColor Green
            Write-Host ""
            $publicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
            Write-Host "您的公钥:" -ForegroundColor Yellow
            Write-Host $publicKey -ForegroundColor Cyan
            Write-Host ""
        } else {
            Write-Host "生成新的 SSH 密钥..." -ForegroundColor Yellow
            $email = Read-Host "请输入您的邮箱"
            ssh-keygen -t rsa -b 4096 -C $email -f "$env:USERPROFILE\.ssh\id_rsa" -N '""'

            Write-Host ""
            $publicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
            Write-Host "您的公钥:" -ForegroundColor Yellow
            Write-Host $publicKey -ForegroundColor Cyan
            Write-Host ""
        }

        Write-Host "步骤 1: 添加 SSH 密钥到 Gitee" -ForegroundColor Yellow
        Write-Host "  1. 访问: https://gitee.com/profile/sshkeys" -ForegroundColor Cyan
        Write-Host "  2. 点击 '添加公钥'" -ForegroundColor White
        Write-Host "  3. 标题: My Computer" -ForegroundColor White
        Write-Host "  4. 公钥: (已复制到剪贴板)" -ForegroundColor White

        # 复制到剪贴板
        $publicKey | Set-Clipboard
        Write-Host ""
        Write-Host "公钥已复制到剪贴板，请粘贴到 Gitee" -ForegroundColor Green

        Read-Host "添加完成后，按 Enter 继续"

        Write-Host ""
        Write-Host "测试 SSH 连接..." -ForegroundColor Yellow
        ssh -T git@gitee.com

        Write-Host ""
        Write-Host "修改远程地址为 SSH..." -ForegroundColor Yellow
        git remote set-url origin "git@gitee.com:19145960820/GLXT.git"

        Write-Host ""
        Write-Host "推送代码..." -ForegroundColor Yellow
        git push -u origin master

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "推送成功!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "推送失败!" -ForegroundColor Red
        }
    }

    "3" {
        Write-Host ""
        Write-Host "使用用户名和密码" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "注意: Gitee 可能要求使用个人访问令牌而不是密码" -ForegroundColor Red
        Write-Host ""

        git push -u origin master
    }

    default {
        Write-Host "无效的选择" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "代码已推送到 Gitee!" -ForegroundColor Green
    Write-Host ""
    Write-Host "仓库地址: https://gitee.com/19145960820/GLXT" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "下一步: 在服务器上部署" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "服务器命令:" -ForegroundColor Cyan
    Write-Host "  git clone https://gitee.com/19145960820/GLXT.git /app/glxt" -ForegroundColor White
    Write-Host "  cd /app/glxt" -ForegroundColor White
    Write-Host "  chmod +x deploy-server.sh" -ForegroundColor White
    Write-Host "  ./deploy-server.sh" -ForegroundColor White
    Write-Host ""
}
Write-Host "=====================================" -ForegroundColor Cyan

Read-Host "按 Enter 退出"
