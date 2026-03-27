# 云服务器 Docker 部署指南

## 📋 部署概览

由于 Docker 在云服务器上，您需要将项目文件上传到服务器，然后在服务器上构建和运行。

---

## 🚀 方式 1: 使用 Git（推荐）

### 步骤 1: 将项目推送到 Git 仓库

在本地（Windows）执行：

```powershell
# 初始化 Git 仓库（如果还没有）
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit"

# 添加远程仓库（替换为您的仓库地址）
git remote add origin https://github.com/YOUR_USERNAME/glxt.git

# 推送到远程仓库
git push -u origin main
```

### 步骤 2: 在服务器上克隆项目

SSH 连接到服务器后执行：

```bash
# 克隆项目
git clone https://github.com/YOUR_USERNAME/glxt.git

# 进入项目目录
cd glxt

# 构建并启动服务
docker compose up -d --build

# 查看运行状态
docker compose ps

# 查看日志
docker compose logs -f
```

---

## 📦 方式 2: 直接上传文件

### 使用 SCP/SFTP 上传

#### Windows PowerShell (使用 SCP)

```powershell
# 压缩项目文件
Compress-Archive -Path glxt\* -DestinationPath glxt.zip

# 上传到服务器（替换服务器信息）
scp glxt.zip root@YOUR_SERVER_IP:/root/

# 或使用 SFTP 工具（推荐）：
# - WinSCP: https://winscp.net/
# - FileZilla: https://filezilla-project.org/
```

#### 在服务器上解压并部署

```bash
# 解压文件
unzip glxt.zip -d /app/glxt

# 进入目录
cd /app/glxt

# 构建并启动
docker compose up -d --build
```

---

## 🌐 方式 3: 使用 Docker Hub（最简单）

### 步骤 1: 在本地构建并推送到 Docker Hub

```powershell
# 如果本地有 Docker（或使用 GitHub Actions）
docker build -t YOUR_DOCKERHUB_USERNAME/glxt-app:latest -f glxt\Dockerfile glxt
docker push YOUR_DOCKERHUB_USERNAME/glxt-app:latest
```

### 步骤 2: 在服务器上拉取并运行

```bash
# 拉取镜像
docker pull YOUR_DOCKERHUB_USERNAME/glxt-app:latest

# 运行容器
docker run -d \
  -p 8080:8080 \
  -p 8081:8081 \
  -e ConnectionStrings__DefaultConnection="Server=139.224.245.244;Port=3306;Database=test;User Id=sym;Password=Sym89@789Ab;" \
  --name glxt-app \
  --restart unless-stopped \
  YOUR_DOCKERHUB_USERNAME/glxt-app:latest

# 查看运行状态
docker ps

# 查看日志
docker logs -f glxt-app
```

---

## 📝 服务器端完整部署脚本

将以下内容保存为 `deploy-server.sh` 并上传到服务器：

```bash
#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}   GLXT Docker 服务器部署脚本${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    echo "请先安装 Docker: https://docs.docker.com/engine/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker 已安装${NC}"

# 检查 docker-compose.yml 是否存在
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}错误: 找不到 docker-compose.yml 文件${NC}"
    echo "请确保在项目目录下运行此脚本"
    exit 1
fi

echo -e "${GREEN}✓ 找到 docker-compose.yml${NC}"
echo ""

# 选择操作
echo -e "${YELLOW}请选择操作:${NC}"
echo "1. 构建并启动服务"
echo "2. 停止服务"
echo "3. 重启服务"
echo "4. 查看日志"
echo "5. 查看运行状态"
echo "6. 清理并重新部署"
echo ""

read -p "请输入选项 (1-6): " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}构建并启动服务...${NC}"
        docker compose down
        docker compose up -d --build

        if [ $? -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✓ 服务启动成功!${NC}"
            echo ""
            docker compose ps
            echo ""
            echo -e "${YELLOW}应用访问地址: http://YOUR_SERVER_IP:5000${NC}"
        else
            echo -e "${RED}✗ 服务启动失败${NC}"
        fi
        ;;

    2)
        echo ""
        echo -e "${YELLOW}停止服务...${NC}"
        docker compose down

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 服务已停止${NC}"
        else
            echo -e "${RED}✗ 停止服务失败${NC}"
        fi
        ;;

    3)
        echo ""
        echo -e "${YELLOW}重启服务...${NC}"
        docker compose restart

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 服务已重启${NC}"
        else
            echo -e "${RED}✗ 重启服务失败${NC}"
        fi
        ;;

    4)
        echo ""
        echo -e "${YELLOW}查看日志 (Ctrl+C 退出)...${NC}"
        docker compose logs -f
        ;;

    5)
        echo ""
        echo -e "${YELLOW}服务运行状态:${NC}"
        docker compose ps
        echo ""
        echo -e "${YELLOW}容器资源使用:${NC}"
        docker stats --no-stream
        ;;

    6)
        echo ""
        read -p "确定要清理所有数据并重新部署? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo -e "${YELLOW}清理并重新部署...${NC}"
            docker compose down -v
            docker system prune -f
            docker compose up -d --build

            if [ $? -eq 0 ]; then
                echo ""
                echo -e "${GREEN}✓ 重新部署成功!${NC}"
                docker compose ps
            else
                echo -e "${RED}✗ 重新部署失败${NC}"
            fi
        else
            echo "取消操作"
        fi
        ;;

    *)
        echo -e "${RED}无效的选项${NC}"
        ;;
esac

echo ""
```

---

## 🔧 服务器环境准备

### 1. 安装 Docker（如果还没有）

#### Ubuntu/Debian:
```bash
# 更新包索引
sudo apt-get update

# 安装依赖
sudo apt-get install -y ca-certificates curl gnupg

# 添加 Docker 官方 GPG 密钥
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 设置 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker compose version
```

#### CentOS/RHEL:
```bash
# 安装 Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. 配置防火墙

```bash
# Ubuntu/Debian (使用 UFW)
sudo ufw allow 5000/tcp
sudo ufw allow 5001/tcp
sudo ufw reload

# CentOS/RHEL (使用 firewalld)
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --permanent --add-port=5001/tcp
sudo firewall-cmd --reload
```

---

## 📤 快速上传脚本

创建 `upload-to-server.ps1` 在本地运行：

```powershell
# 服务器配置（请修改）
$SERVER_IP = "YOUR_SERVER_IP"
$SERVER_USER = "root"
$SERVER_PATH = "/app/glxt"

Write-Host "压缩项目文件..." -ForegroundColor Yellow
Compress-Archive -Path glxt\* -DestinationPath glxt.zip -Force

Write-Host "上传到服务器..." -ForegroundColor Yellow
scp glxt.zip ${SERVER_USER}@${SERVER_IP}:${SERVER_PATH}/

Write-Host "在服务器上部署..." -ForegroundColor Yellow
ssh ${SERVER_USER}@${SERVER_IP} @"
cd ${SERVER_PATH}
unzip -o glxt.zip
chmod +x deploy-server.sh
./deploy-server.sh
"@

Write-Host "部署完成!" -ForegroundColor Green
Remove-Item glxt.zip
```

---

## 🔍 验证部署

部署完成后，测试应用：

```bash
# 检查容器状态
docker compose ps

# 检查日志
docker compose logs

# 测试 API
curl http://localhost:5000/api/health
curl http://YOUR_SERVER_IP:5000/api/health

# 检查数据库连接
docker compose exec glxt-api curl http://localhost:8080/api/health
```

---

## 📊 监控和维护

### 查看日志
```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f glxt-api

# 查看最后 100 行日志
docker compose logs --tail=100
```

### 更新应用
```bash
# 1. 拉取最新代码
git pull

# 2. 重新构建并启动
docker compose up -d --build

# 3. 查看状态
docker compose ps
```

### 备份数据
```bash
# 备份数据库
docker compose exec sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'Sym89@789Ab' \
  -Q "BACKUP DATABASE [GlxtDb] TO DISK = N'/var/opt/mssql/backup/glxt.bak'"

# 复制备份文件
docker cp glxt-sqlserver:/var/opt/mssql/backup/glxt.bak ./backup/
```

---

## ⚠️ 常见问题

### 问题 1: 端口被占用
```bash
# 查看端口占用
sudo netstat -tlnp | grep 5000

# 修改 docker-compose.yml 中的端口映射
# ports:
#   - "8080:8080"  # 改为其他端口
```

### 问题 2: 内存不足
```bash
# 查看系统资源
free -h
df -h

# 清理 Docker 资源
docker system prune -a --volumes
```

### 问题 3: 数据库连接失败
```bash
# 检查数据库容器
docker compose logs sqlserver

# 测试数据库连接
docker compose exec sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'Sym89@789Ab' -Q "SELECT @@VERSION"
```

---

## 🎯 下一步

1. 选择合适的上传方式（推荐使用 Git）
2. 在服务器上部署应用
3. 配置域名和 HTTPS
4. 设置自动备份
5. 配置监控和告警
