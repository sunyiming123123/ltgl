# Gitee (码云) 部署完整指南

## 📋 第一步：创建 Gitee 账号和仓库

### 1. 注册/登录 Gitee
- 访问：https://gitee.com/
- 如果没有账号，点击"注册"创建账号
- 使用您的邮箱注册即可

### 2. 创建新仓库
1. 登录后，点击右上角的 "+" → "新建仓库"
2. 或直接访问：https://gitee.com/projects/new

3. 填写仓库信息：
   - **仓库名称**：glxt（或其他名称）
   - **路径**：会自动生成，如 `your-username/glxt`
   - **是否开源**：建议选择"私有"
   - **初始化仓库**：❌ **不要勾选** "使用 Readme 文件初始化这个仓库"
   - **语言**：C#
   - **.gitignore**：不选择（我们已经有了）

4. 点击"创建"

### 3. 获取仓库地址
创建完成后，您会看到一个页面，上面有仓库地址，格式如下：
```
https://gitee.com/YOUR_USERNAME/glxt.git
```

**注意**：`YOUR_USERNAME` 是您的 Gitee 用户名，不是邮箱！

---

## 🔑 第二步：配置 Git 凭证

### 方式 1: 生成私人令牌（推荐）

1. **生成令牌**
   - 访问：https://gitee.com/profile/personal_access_tokens
   - 点击"生成新令牌"
   - 描述：`glxt-deploy`
   - 权限：勾选 `projects`（仓库权限）
   - 点击"提交"
   - **复制生成的令牌**（只显示一次！）

2. **使用令牌推送**
   ```powershell
   # 当提示输入密码时，使用令牌代替密码
   # 用户名：你的 Gitee 用户名
   # 密码：刚才复制的令牌
   ```

### 方式 2: 配置 SSH 密钥

1. **生成 SSH 密钥**
   ```powershell
   # 检查是否已有密钥
   ls ~/.ssh/id_rsa.pub

   # 如果没有，生成新密钥
   ssh-keygen -t rsa -C "your-email@example.com"
   # 一路回车即可

   # 查看公钥
   cat ~/.ssh/id_rsa.pub
   # 复制输出的内容
   ```

2. **添加到 Gitee**
   - 访问：https://gitee.com/profile/sshkeys
   - 点击"添加公钥"
   - 标题：`My Computer`
   - 公钥：粘贴刚才复制的内容
   - 点击"确定"

3. **测试连接**
   ```powershell
   ssh -T git@gitee.com
   # 看到 "Hi xxx! You've successfully authenticated" 即成功
   ```

4. **使用 SSH 地址推送**
   ```powershell
   # 修改远程仓库地址为 SSH 格式
   git remote set-url origin git@gitee.com:YOUR_USERNAME/glxt.git
   git push -u origin master
   ```

---

## 🚀 第三步：推送代码

### 准备工作（已完成）
```powershell
# 这些步骤已经完成了
git add .
git commit -m "Initial deployment"
```

### 推送代码

#### 方式 A: 使用 HTTPS + 令牌
```powershell
# 1. 设置远程仓库（使用正确的用户名）
git remote remove origin  # 移除之前错误的配置
git remote add origin https://gitee.com/YOUR_USERNAME/glxt.git

# 2. 推送（会提示输入用户名和密码）
git push -u origin master

# 用户名：你的 Gitee 用户名（不是邮箱）
# 密码：个人访问令牌（不是登录密码）
```

#### 方式 B: 使用 SSH
```powershell
# 1. 设置远程仓库（SSH 格式）
git remote remove origin
git remote add origin git@gitee.com:YOUR_USERNAME/glxt.git

# 2. 推送（配置了 SSH 密钥后无需输入密码）
git push -u origin master
```

---

## 📦 第四步：在服务器上部署

### 1. 通过云服务器控制台连接

**阿里云 ECS：**
1. 登录：https://ecs.console.aliyun.com/
2. 找到您的实例
3. 点击"远程连接" → "通过Workbench远程连接"
4. 进入终端

**腾讯云 CVM：**
1. 登录：https://console.cloud.tencent.com/cvm/instance
2. 找到您的实例
3. 点击"登录"
4. 选择"标准登录方式"

### 2. 在服务器上执行命令

```bash
# 1. 安装 Git（如果没有）
sudo yum install git -y          # CentOS/RHEL
# 或
sudo apt update && sudo apt install git -y  # Ubuntu/Debian

# 2. 克隆项目
git clone https://gitee.com/YOUR_USERNAME/glxt.git /app/glxt

# 如果是私有仓库，会提示输入用户名和密码/令牌

# 3. 进入目录
cd /app/glxt

# 4. 设置权限
chmod +x deploy-server.sh

# 5. 运行部署脚本
./deploy-server.sh

# 6. 选择选项 1: 构建并启动服务
```

### 3. 查看应用状态

```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f

# 查看应用
curl http://localhost:5000
```

### 4. 访问应用

在浏览器中访问：
```
http://YOUR_SERVER_PUBLIC_IP:5000
```

---

## 🔄 后续更新流程

### 本地修改代码后：
```powershell
# 1. 添加更改
git add .

# 2. 提交
git commit -m "Update: 描述你的更改"

# 3. 推送
git push
```

### 服务器更新：
```bash
# 1. 进入项目目录
cd /app/glxt

# 2. 拉取最新代码
git pull

# 3. 重新部署
./deploy-server.sh
# 选择选项 6: 更新服务
```

---

## 🔍 常见问题

### Q1: 推送时提示"Authentication failed"
**解决方案：**
1. 确认使用的是**用户名**，不是邮箱
2. 确认密码使用的是**个人访问令牌**，不是登录密码
3. 或者使用 SSH 方式

### Q2: 克隆时很慢或超时
**解决方案：**
```bash
# 在服务器上设置 Git 代理（如果需要）
git config --global http.proxy http://proxy-server:port
```

### Q3: 推送被拒绝 (rejected)
**解决方案：**
```powershell
# 先拉取远程更改
git pull origin master --allow-unrelated-histories

# 再推送
git push -u origin master
```

### Q4: 仓库地址错误
**解决方案：**
```powershell
# 查看当前远程地址
git remote -v

# 修改远程地址
git remote set-url origin https://gitee.com/CORRECT_USERNAME/glxt.git
```

---

## 📝 快速命令参考

### 获取 Gitee 用户名
1. 登录 Gitee
2. 点击右上角头像
3. 查看个人主页 URL：`https://gitee.com/YOUR_USERNAME`
4. `YOUR_USERNAME` 就是你的用户名

### 完整命令流程
```powershell
# 本地（Windows PowerShell）
cd D:\test\glxt
git remote remove origin
git remote add origin https://gitee.com/YOUR_USERNAME/glxt.git
git push -u origin master
# 输入用户名和令牌

# 服务器（通过云控制台 Web 终端）
git clone https://gitee.com/YOUR_USERNAME/glxt.git /app/glxt
cd /app/glxt
chmod +x deploy-server.sh
./deploy-server.sh
```

---

## 🎯 下一步

按照以上步骤完成后：
1. 在浏览器访问：`http://YOUR_SERVER_IP:5000`
2. 访问 Swagger 文档：`http://YOUR_SERVER_IP:5000/swagger`
3. 测试 API 是否正常工作

需要帮助？请告诉我您在哪一步遇到了问题！
