# 创建 Gitee 仓库并推送 - 快速指南

## 📋 您的信息
- Gitee 用户名: 19145960820
- 仓库名: GLXT
- 仓库地址: https://gitee.com/19145960820/GLXT.git

## 🚀 第一步：创建 Gitee 仓库

### 方式 1: 通过网页创建（推荐）

1. **访问创建页面**

   点击这个链接：https://gitee.com/projects/new

   或者：
   - 登录 Gitee: https://gitee.com/
   - 点击右上角 "+" 按钮
   - 选择 "新建仓库"

2. **填写仓库信息**
   ```
   仓库名称: GLXT
   路径: 19145960820/GLXT (自动生成)
   介绍: .NET 8 聊天应用
   是否开源: 私有（推荐）或公开

   ⚠️ 重要：不要勾选以下选项
   [ ] 使用 Readme 文件初始化这个仓库
   [ ] 设置 .gitignore
   [ ] 设置许可证
   ```

3. **点击"创建"按钮**

### 方式 2: 通过命令行创建

如果您有 Gitee API Token，可以使用命令创建：

```powershell
# 需要先在 https://gitee.com/profile/personal_access_tokens 生成令牌
# 然后运行：
$token = "YOUR_ACCESS_TOKEN"
$body = @{
    name = "GLXT"
    description = ".NET 8 Chat Application"
    private = $true
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://gitee.com/api/v5/user/repos" -Method Post -Headers @{"Authorization"="token $token"; "Content-Type"="application/json"} -Body $body
```

---

## 🔑 第二步：配置认证

### 方式 A: 使用个人访问令牌（推荐）

1. **生成令牌**

   访问：https://gitee.com/profile/personal_access_tokens

   - 点击 "生成新令牌"
   - 令牌描述: `GLXT部署`
   - 权限: 勾选 `projects` (完整的仓库控制权限)
   - 点击 "提交"
   - **立即复制令牌**（只显示一次！）

2. **保存令牌**

   将令牌保存到安全的地方，例如：
   ```
   令牌: ghp_xxxxxxxxxxxxxxxxxxxx (示例)
   ```

### 方式 B: 配置 SSH 密钥

1. **生成 SSH 密钥**
   ```powershell
   # 检查是否已有密钥
   if (Test-Path ~/.ssh/id_rsa.pub) {
       Write-Host "SSH key already exists"
       Get-Content ~/.ssh/id_rsa.pub
   } else {
       # 生成新密钥
       ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
       # 一路回车，使用默认设置
       Get-Content ~/.ssh/id_rsa.pub
   }
   ```

2. **添加到 Gitee**
   - 访问：https://gitee.com/profile/sshkeys
   - 点击 "添加公钥"
   - 标题: `My Windows PC`
   - 公钥: 粘贴上面命令输出的内容
   - 点击 "确定"

3. **测试连接**
   ```powershell
   ssh -T git@gitee.com
   ```
   看到 "Hi 19145960820!" 即成功

4. **修改为 SSH 地址**
   ```powershell
   git remote set-url origin git@gitee.com:19145960820/GLXT.git
   ```

---

## 📤 第三步：推送代码

### 使用 HTTPS + 令牌

```powershell
# 推送代码
git push -u origin master

# 当提示时输入：
# Username: 19145960820
# Password: [粘贴您的个人访问令牌]
```

### 使用 SSH（配置密钥后）

```powershell
# 修改为 SSH 地址
git remote set-url origin git@gitee.com:19145960820/GLXT.git

# 推送（无需输入密码）
git push -u origin master
```

---

## ✅ 第四步：验证推送成功

推送成功后，访问您的仓库：

🔗 https://gitee.com/19145960820/GLXT

您应该能看到所有文件已经上传。

---

## 🖥️ 第五步：在服务器上部署

### 1. 连接到服务器

通过云服务器控制台的 Web 终端连接（不需要 SSH 配置）：

**阿里云**：
- 控制台 → ECS 实例 → 远程连接 → Workbench

**腾讯云**：
- 控制台 → 云服务器 → 登录 → 标准登录

### 2. 在服务器上执行

```bash
# 安装 Git（如果没有）
sudo yum install git -y
# 或 Ubuntu/Debian:
# sudo apt update && sudo apt install git -y

# 克隆仓库
git clone https://gitee.com/19145960820/GLXT.git /app/glxt

# 如果是私有仓库，输入：
# Username: 19145960820
# Password: [您的个人访问令牌]

# 进入目录
cd /app/glxt

# 设置权限
chmod +x deploy-server.sh

# 运行部署
./deploy-server.sh

# 选择选项 1: 构建并启动服务
```

### 3. 查看运行状态

```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f

# 测试应用
curl http://localhost:5000
```

### 4. 访问应用

在浏览器中打开：
```
http://YOUR_SERVER_PUBLIC_IP:5000
```

Swagger 文档：
```
http://YOUR_SERVER_PUBLIC_IP:5000/swagger
```

---

## 🔄 后续更新

### 本地修改后推送

```powershell
git add .
git commit -m "Update: 描述您的更改"
git push
```

### 服务器更新

```bash
cd /app/glxt
git pull
./deploy-server.sh
# 选择选项 6: 更新服务
```

---

## ❓ 常见问题

### Q: 推送时提示 "Authentication failed"

**解决方案**：
- 用户名输入: `19145960820`
- 密码输入: **个人访问令牌**（不是登录密码）
- 或使用 SSH 方式

### Q: 克隆时提示 "404 not found"

**原因**: 仓库是私有的

**解决方案**:
```bash
# 使用带认证的 URL
git clone https://19145960820:YOUR_TOKEN@gitee.com/19145960820/GLXT.git /app/glxt
```

### Q: 推送被拒绝

**解决方案**:
```powershell
# 如果仓库已有内容
git pull origin master --allow-unrelated-histories
git push -u origin master
```

---

## 📞 需要帮助？

如果遇到问题，请检查：

1. ✅ 仓库是否已创建: https://gitee.com/19145960820/GLXT
2. ✅ 是否生成了个人访问令牌
3. ✅ 推送时使用令牌而不是密码
4. ✅ 网络连接是否正常

---

## 🎯 下一步操作

1. **立即创建仓库**：https://gitee.com/projects/new
2. **生成访问令牌**：https://gitee.com/profile/personal_access_tokens
3. **在 PowerShell 中执行**：
   ```powershell
   git push -u origin master
   ```
4. **在服务器上克隆并部署**

完成后，您的应用就部署成功了！🎉
