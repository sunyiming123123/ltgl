# Git 部署指南

## 为什么使用 Git？

- ✅ 不需要配置 SSH 密钥
- ✅ 支持增量更新
- ✅ 可以版本控制
- ✅ 适合团队协作

## 部署步骤

### 步骤 1: 本地推送到 Git 仓库

```powershell
# 初始化 Git（如果还没有）
git init

# 添加远程仓库（使用您的仓库地址）
# GitHub
git remote add origin https://github.com/YOUR_USERNAME/glxt.git

# Gitee（国内推荐）
git remote add origin https://gitee.com/YOUR_USERNAME/glxt.git

# 添加所有文件
git add .

# 提交
git commit -m "Initial deployment"

# 推送到远程仓库
git push -u origin main
```

### 步骤 2: 在服务器上克隆

通过云服务器控制台的 Web Terminal 或 VNC 连接到服务器，然后执行：

```bash
# 克隆项目
git clone https://github.com/YOUR_USERNAME/glxt.git /app/glxt
# 或使用 Gitee
git clone https://gitee.com/YOUR_USERNAME/glxt.git /app/glxt

# 进入目录
cd /app/glxt

# 设置权限
chmod +x deploy-server.sh

# 运行部署
./deploy-server.sh
# 选择选项 1: 构建并启动服务
```

### 步骤 3: 后续更新

**本地：**
```powershell
git add .
git commit -m "Update application"
git push
```

**服务器：**
```bash
cd /app/glxt
git pull
./deploy-server.sh
# 选择选项 6: 更新服务
```

---

## 使用云服务器控制台

### 阿里云 ECS

1. 登录阿里云控制台
2. 进入 ECS 实例管理
3. 点击"远程连接" → "VNC 连接"
4. 输入密码进入终端
5. 执行上述命令

### 腾讯云 CVM

1. 登录腾讯云控制台
2. 进入云服务器列表
3. 点击"登录"
4. 选择"标准登录方式"
5. 执行上述命令

### AWS EC2

1. 登录 AWS 控制台
2. 进入 EC2 实例
3. 选择实例 → "连接"
4. 使用 "EC2 Instance Connect"
5. 执行上述命令

---

## 快速开始（Gitee）

### 1. 创建 Gitee 仓库

访问：https://gitee.com/projects/new

### 2. 本地配置

```powershell
# 在项目目录
cd D:\test\glxt

# 初始化 Git
git init

# 添加 .gitignore（如果没有）
@"
bin/
obj/
.vs/
*.user
*.suo
"@ | Out-File -FilePath .gitignore -Encoding utf8

# 添加文件
git add .

# 提交
git commit -m "Initial commit"

# 添加远程仓库（替换为您的仓库地址）
git remote add origin https://gitee.com/YOUR_USERNAME/glxt.git

# 推送
git push -u origin master
```

### 3. 服务器部署

```bash
# 通过云控制台 Web 终端连接，然后执行：

# 安装 Git（如果没有）
yum install git -y  # CentOS
# 或
apt install git -y  # Ubuntu

# 克隆项目
git clone https://gitee.com/YOUR_USERNAME/glxt.git /app/glxt

# 部署
cd /app/glxt
chmod +x deploy-server.sh
./deploy-server.sh
```

---

## 不使用 Git 的替代方案

### 方案 A: 云服务器控制台文件上传

1. 通过云服务器控制台的文件管理功能
2. 直接上传 `glxt-deploy.zip`
3. 在 Web 终端中解压部署

### 方案 B: 使用 SFTP 工具

推荐工具：
- **WinSCP**：https://winscp.net/
- **FileZilla**：https://filezilla-project.org/

配置：
- 协议：SFTP
- 主机：您的服务器公网 IP
- 端口：22（或自定义端口）
- 用户名：root
- 密码：您的服务器密码

上传后在服务器上：
```bash
cd /app/glxt
unzip -o glxt-deploy.zip
chmod +x deploy-server.sh
./deploy-server.sh
```

---

## 故障排查

### 问题：找不到 Git 命令
```bash
# CentOS
sudo yum install git -y

# Ubuntu/Debian
sudo apt update
sudo apt install git -y
```

### 问题：Git clone 很慢
```bash
# 使用 Gitee（国内镜像）替代 GitHub
git clone https://gitee.com/YOUR_USERNAME/glxt.git
```

### 问题：Permission denied
```bash
# 修复权限
sudo chown -R $USER:$USER /app/glxt
chmod +x /app/glxt/deploy-server.sh
```
