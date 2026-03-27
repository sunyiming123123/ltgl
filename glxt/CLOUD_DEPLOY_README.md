# 云服务器部署快速指南

## 🚀 三种部署方式

### 方式 1: 自动上传脚本（最简单）⭐

在本地 Windows PowerShell 中运行：

```powershell
.\glxt\upload-to-server.ps1
```

脚本会自动：
1. 压缩项目文件
2. 上传到服务器
3. 解压并准备部署环境
4. 可选择立即在服务器上部署

### 方式 2: 使用 Git（推荐）

**本地操作：**
```powershell
# 提交并推送代码
git add .
git commit -m "准备部署"
git push origin main
```

**服务器操作：**
```bash
# 克隆或拉取项目
git clone https://github.com/YOUR_USERNAME/glxt.git
# 或
cd glxt && git pull

# 运行部署脚本
chmod +x deploy-server.sh
./deploy-server.sh
# 选择选项 1: 构建并启动服务
```

### 方式 3: 手动上传

1. 使用 WinSCP 或 FileZilla 上传 `glxt` 文件夹到服务器
2. SSH 连接到服务器
3. 运行部署脚本

---

## 📋 前置要求

### 本地 Windows 需要：
- PowerShell
- SSH 客户端（Windows 10+ 自带）
- 或者 Git + WinSCP/FileZilla

### 服务器需要：
- Ubuntu 18.04+ / CentOS 7+ / Debian 10+
- Docker 和 Docker Compose
- SSH 访问权限

---

## 🔧 服务器首次配置

### 1. 安装 Docker

SSH 连接到服务器后执行：

```bash
# Ubuntu/Debian 一键安装
curl -fsSL https://get.docker.com | sh

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker compose version
```

### 2. 配置防火墙

```bash
# 开放应用端口
sudo ufw allow 5000/tcp
sudo ufw allow 5001/tcp

# 或使用 firewalld (CentOS)
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --permanent --add-port=5001/tcp
sudo firewall-cmd --reload
```

---

## 📤 部署步骤

### 步骤 1: 上传项目（选择一种方式）

#### 方式 A: 使用自动脚本
```powershell
# 在本地运行
.\glxt\upload-to-server.ps1
```

#### 方式 B: 使用 Git
```bash
# 在服务器上
git clone https://github.com/YOUR_USERNAME/glxt.git /app/glxt
cd /app/glxt
```

#### 方式 C: 手动上传
使用 WinSCP/FileZilla 上传项目文件

### 步骤 2: 在服务器上部署

```bash
# SSH 连接到服务器
ssh root@YOUR_SERVER_IP

# 进入项目目录
cd /app/glxt

# 给部署脚本执行权限
chmod +x deploy-server.sh

# 运行部署脚本
./deploy-server.sh

# 选择选项 1: 构建并启动服务
```

### 步骤 3: 验证部署

```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f

# 测试 API
curl http://localhost:5000/api/health
```

---

## 🌐 访问应用

部署成功后，通过以下地址访问：

- **HTTP**: `http://YOUR_SERVER_IP:5000`
- **Swagger**: `http://YOUR_SERVER_IP:5000/swagger`

---

## 📊 常用管理命令

### 在服务器上执行部署脚本：
```bash
cd /app/glxt
./deploy-server.sh
```

### 快速命令：
```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看日志
docker compose logs -f

# 查看状态
docker compose ps

# 更新服务
git pull  # 如果使用 Git
docker compose up -d --build
```

---

## 🔄 更新应用

### 使用 Git 方式：
```bash
cd /app/glxt
git pull
./deploy-server.sh
# 选择选项 6: 更新服务
```

### 使用上传脚本方式：
```powershell
# 在本地运行
.\glxt\upload-to-server.ps1
# 然后在服务器上选择选项 6
```

---

## 💾 备份和恢复

### 备份数据库
```bash
./deploy-server.sh
# 选择选项 8: 备份数据库
```

备份文件保存在 `./backups/` 目录

### 恢复数据库
```bash
# 上传备份文件到服务器
scp glxt_backup.bak root@SERVER_IP:/app/glxt/backups/

# 在服务器上恢复
docker compose exec sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Sym89@789Ab" \
  -Q "RESTORE DATABASE [GlxtDb] FROM DISK = N'/var/opt/mssql/backup/glxt_backup.bak' WITH REPLACE"
```

---

## 🐛 故障排查

### 容器无法启动
```bash
# 查看详细日志
docker compose logs

# 查看特定服务日志
docker compose logs glxt-api
docker compose logs sqlserver
```

### 端口被占用
```bash
# 查看端口占用
sudo netstat -tlnp | grep 5000

# 修改 docker-compose.yml 中的端口
# ports:
#   - "8080:8080"  # 改为其他端口
```

### 数据库连接失败
```bash
# 检查数据库容器状态
docker compose ps

# 测试数据库连接
docker compose exec sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Sym89@789Ab" -Q "SELECT @@VERSION"
```

### 清理并重新部署
```bash
./deploy-server.sh
# 选择选项 7: 清理并重新部署
```

---

## 📚 相关文档

- `SERVER_DEPLOY_GUIDE.md` - 详细部署指南
- `DOCKER_COMMANDS.md` - Docker 命令参考
- `deploy-server.sh` - 服务器部署脚本
- `upload-to-server.ps1` - Windows 上传脚本

---

## 🆘 需要帮助？

如果遇到问题：
1. 检查服务器日志: `docker compose logs -f`
2. 查看容器状态: `docker compose ps`
3. 确认防火墙规则: `sudo ufw status`
4. 检查 Docker 状态: `sudo systemctl status docker`

---

## ⚡ 快速命令参考

```bash
# 在本地 Windows
.\glxt\upload-to-server.ps1                    # 上传项目

# 在云服务器
cd /app/glxt && ./deploy-server.sh             # 打开部署菜单
docker compose up -d --build                   # 快速重启
docker compose logs -f                         # 查看日志
docker compose ps                              # 查看状态
```
