# Docker 部署脚本
# 使用方法: .\deploy-docker.ps1

Write-Host "=====================================" -ForegroundColor Green
Write-Host "   GLXT Docker 部署脚本" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# 检查 Docker 是否安装
Write-Host "检查 Docker 环境..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker 已安装: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ 错误: Docker 未安装或未启动" -ForegroundColor Red
    Write-Host ""
    Write-Host "请先安装 Docker Desktop:" -ForegroundColor Yellow
    Write-Host "下载地址: https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "按任意键退出"
    exit 1
}

Write-Host ""

# 询问用户操作
Write-Host "请选择操作:" -ForegroundColor Cyan
Write-Host "1. 构建 Docker 镜像" -ForegroundColor White
Write-Host "2. 推送镜像到 Docker Hub" -ForegroundColor White
Write-Host "3. 使用 Docker Compose 启动（本地测试）" -ForegroundColor White
Write-Host "4. 停止 Docker Compose 服务" -ForegroundColor White
Write-Host "5. 完整部署流程（构建+推送）" -ForegroundColor White
Write-Host ""

$choice = Read-Host "请输入选项 (1-5)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "   构建 Docker 镜像" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host ""

        $imageName = Read-Host "请输入镜像名称 (默认: glxt-app)"
        if ([string]::IsNullOrWhiteSpace($imageName)) {
            $imageName = "glxt-app"
        }

        $imageTag = Read-Host "请输入镜像标签 (默认: latest)"
        if ([string]::IsNullOrWhiteSpace($imageTag)) {
            $imageTag = "latest"
        }

        Write-Host ""
        Write-Host "开始构建镜像: ${imageName}:${imageTag}" -ForegroundColor Yellow
        docker build -t "${imageName}:${imageTag}" .

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✓ 镜像构建成功!" -ForegroundColor Green
            Write-Host ""
            Write-Host "查看镜像:" -ForegroundColor Cyan
            docker images | Select-String $imageName
        } else {
            Write-Host ""
            Write-Host "✗ 镜像构建失败!" -ForegroundColor Red
        }
    }

    "2" {
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "   推送镜像到 Docker Hub" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host ""

        # 检查是否已登录
        Write-Host "检查 Docker Hub 登录状态..." -ForegroundColor Yellow
        $loginCheck = docker info 2>&1 | Select-String "Username"

        if (-not $loginCheck) {
            Write-Host "您还未登录 Docker Hub" -ForegroundColor Yellow
            Write-Host ""
            $login = Read-Host "是否现在登录? (Y/N)"
            if ($login -eq "Y" -or $login -eq "y") {
                docker login
            } else {
                Write-Host "取消操作" -ForegroundColor Red
                exit 1
            }
        }

        Write-Host ""
        $dockerUsername = Read-Host "请输入您的 Docker Hub 用户名"
        $imageName = Read-Host "请输入镜像名称 (默认: glxt-app)"
        if ([string]::IsNullOrWhiteSpace($imageName)) {
            $imageName = "glxt-app"
        }

        $imageTag = Read-Host "请输入镜像标签 (默认: latest)"
        if ([string]::IsNullOrWhiteSpace($imageTag)) {
            $imageTag = "latest"
        }

        $fullImageName = "${dockerUsername}/${imageName}:${imageTag}"

        Write-Host ""
        Write-Host "标记镜像: ${imageName}:${imageTag} -> ${fullImageName}" -ForegroundColor Yellow
        docker tag "${imageName}:${imageTag}" $fullImageName

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "推送镜像到 Docker Hub..." -ForegroundColor Yellow
            docker push $fullImageName

            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "✓ 镜像推送成功!" -ForegroundColor Green
                Write-Host ""
                Write-Host "您可以在以下地址查看: https://hub.docker.com/r/${dockerUsername}/${imageName}" -ForegroundColor Cyan
            } else {
                Write-Host ""
                Write-Host "✗ 镜像推送失败!" -ForegroundColor Red
            }
        } else {
            Write-Host ""
            Write-Host "✗ 镜像标记失败!" -ForegroundColor Red
        }
    }

    "3" {
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "   启动 Docker Compose 服务" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host ""

        Write-Host "启动服务..." -ForegroundColor Yellow
        docker-compose up -d --build

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✓ 服务启动成功!" -ForegroundColor Green
            Write-Host ""
            Write-Host "查看运行状态:" -ForegroundColor Cyan
            docker-compose ps
            Write-Host ""
            Write-Host "应用访问地址: http://localhost:5000" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "查看日志命令: docker-compose logs -f" -ForegroundColor Yellow
        } else {
            Write-Host ""
            Write-Host "✗ 服务启动失败!" -ForegroundColor Red
        }
    }

    "4" {
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "   停止 Docker Compose 服务" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host ""

        $removeVolumes = Read-Host "是否删除数据卷? (Y/N，默认: N)"

        if ($removeVolumes -eq "Y" -or $removeVolumes -eq "y") {
            Write-Host "停止服务并删除数据卷..." -ForegroundColor Yellow
            docker-compose down -v
        } else {
            Write-Host "停止服务..." -ForegroundColor Yellow
            docker-compose down
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✓ 服务已停止!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "✗ 停止服务失败!" -ForegroundColor Red
        }
    }

    "5" {
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "   完整部署流程" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host ""

        $dockerUsername = Read-Host "请输入您的 Docker Hub 用户名"
        $imageName = Read-Host "请输入镜像名称 (默认: glxt-app)"
        if ([string]::IsNullOrWhiteSpace($imageName)) {
            $imageName = "glxt-app"
        }

        $imageTag = Read-Host "请输入镜像标签 (默认: latest)"
        if ([string]::IsNullOrWhiteSpace($imageTag)) {
            $imageTag = "latest"
        }

        # 步骤 1: 构建镜像
        Write-Host ""
        Write-Host "[1/3] 构建 Docker 镜像..." -ForegroundColor Yellow
        docker build -t "${imageName}:${imageTag}" .

        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ 镜像构建失败!" -ForegroundColor Red
            exit 1
        }

        # 步骤 2: 登录 Docker Hub
        Write-Host ""
        Write-Host "[2/3] 登录 Docker Hub..." -ForegroundColor Yellow
        docker login

        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ 登录失败!" -ForegroundColor Red
            exit 1
        }

        # 步骤 3: 标记并推送镜像
        $fullImageName = "${dockerUsername}/${imageName}:${imageTag}"

        Write-Host ""
        Write-Host "[3/3] 推送镜像到 Docker Hub..." -ForegroundColor Yellow
        docker tag "${imageName}:${imageTag}" $fullImageName
        docker push $fullImageName

        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "=====================================" -ForegroundColor Green
            Write-Host "   ✓ 部署完成!" -ForegroundColor Green
            Write-Host "=====================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "镜像地址: ${fullImageName}" -ForegroundColor Cyan
            Write-Host "Docker Hub: https://hub.docker.com/r/${dockerUsername}/${imageName}" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "在服务器上运行:" -ForegroundColor Yellow
            Write-Host "docker pull ${fullImageName}" -ForegroundColor White
            Write-Host "docker run -d -p 8080:8080 --name glxt-app ${fullImageName}" -ForegroundColor White
        } else {
            Write-Host ""
            Write-Host "✗ 部署失败!" -ForegroundColor Red
        }
    }

    default {
        Write-Host ""
        Write-Host "无效的选项!" -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "按任意键退出"
