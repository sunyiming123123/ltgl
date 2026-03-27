# 🚀 一键部署完全指南

服务器: **139.224.245.244** (阿里云)

---

## 📋 部署前准备（5 分钟）

### ✅ 1. 确保本地有 SSH 客户端

**Windows 10/11** 已内置，测试一下：

```powershell
ssh
```

如果提示 `usage: ssh ...` 说明已安装。

### ✅ 2. 测试 SSH 连接

```powershell
ssh root@139.224.245.244
# 输入密码后，如果能登录说明连接正常
# 输入 exit 退出
```

### ✅ 3. 配置阿里云安全组（重要！）

**📖 详细步骤请查看：`ALIYUN-SECURITY-GROUP.md`**

必须开放端口 **5000**，否则无法从外网访问 API！

---

## 🚀 一键部署（3 步）

### 步骤 1: 进入项目目录

打开 **PowerShell**（右键管理员模式），运行：

```powershell
# 替换成您的实际项目路径
cd D:\projects\glxt
```

### 步骤 2: 运行部署脚本

```powershell
.\deploy-to-server.ps1
```

**脚本会自动完成：**
- ✅ 在服务器上安装 Docker
- ✅ 上传项目文件
- ✅ 构建 Docker 镜像
- ✅ 启动容器（API + SQL Server）
- ✅ 运行数据库迁移

**预计时间：5-10 分钟（首次运行需要下载镜像）**

### 步骤 3: 验证部署

```powershell
.\verify-deployment.ps1
```

**看到以下输出说明成功：**
```
✅ API 可访问 (状态码: 200)
✅ 注册成功
✅ 登录成功！
```

---

## 🌐 访问您的 API

部署成功后：

- **API 地址**: http://139.224.245.244:5000
- **Swagger 文档**: http://139.224.245.244:5000/swagger （如果已配置）
- **健康检查**: http://139.224.245.244:5000/health

---

## 🧪 快速测试

### 在浏览器中访问：
```
http://139.224.245.244:5000/health
```

### 使用 PowerShell 测试注册：

```powershell
$body = @{
    username = "myuser"
    email = "user@example.com"
    password = "MyPass@123"
    fullName = "My Name"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://139.224.245.244:5000/api/users/register `
    -Method POST `
    -ContentType "application/json" `
    -Body $body
```

### 测试登录：

```powershell
$body = @{
    username = "myuser"
    password = "MyPass@123"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://139.224.245.244:5000/api/users/login `
    -Method POST `
    -ContentType "application/json" `
    -Body $body
```

---

## 🔧 管理命令

### 连接到服务器：

```powershell
ssh root@139.224.245.244
```

### 查看容器状态：

```bash
cd /opt/glxt
docker compose ps
```

### 查看日志：

```bash
# API 日志
docker logs glxt-api -f

# SQL Server 日志
docker logs glxt-sqlserver -f

# 按 Ctrl+C 退出日志查看
```

### 重启服务：

```bash
cd /opt/glxt
docker compose restart
```

### 停止服务：

```bash
cd /opt/glxt
docker compose down
```

### 更新代码后重新部署：

```powershell
# 在本地 PowerShell 中运行
.\deploy-to-server.ps1
```

---

## 🐛 常见问题

### ❌ 问题 1: 无法访问 API (ERR_CONNECTION_REFUSED)

**原因**: 阿里云安全组未开放端口 5000

**解决**:
1. 登录阿里云控制台
2. 找到您的 ECS 实例
3. 配置安全组，开放端口 5000
4. 详见 `ALIYUN-SECURITY-GROUP.md`

### ❌ 问题 2: 部署脚本执行失败

**检查 SSH 连接**:
```powershell
ssh root@139.224.245.244
```

**查看服务器日志**:
```bash
docker logs glxt-api --tail 50
```

### ❌ 问题 3: 数据库迁移失败

**手动运行迁移**:
```bash
ssh root@139.224.245.244
docker exec -it glxt-api dotnet ef database update
```

### ❌ 问题 4: 容器一直重启

**查看详细日志**:
```bash
ssh root@139.224.245.244
docker logs glxt-api --tail 100
```

**常见原因**:
- SQL Server 未完全启动（等待 30-60 秒）
- 配置文件错误（检查 docker-compose.yml）
- 内存不足（至少需要 2GB）

---

## 📊 查看系统资源

```bash
# 查看容器资源使用
docker stats

# 查看磁盘空间
df -h

# 查看内存使用
free -h
```

---

## 🔄 完全重新部署

如果需要从头开始：

```bash
# SSH 登录服务器
ssh root@139.224.245.244

# 停止并删除所有容器和数据
cd /opt/glxt
docker compose down -v

# 删除项目目录
rm -rf /opt/glxt

# 退出服务器
exit
```

然后在本地重新运行：
```powershell
.\deploy-to-server.ps1
```

---

## 📞 需要帮助？

如果遇到问题，请提供：
1. 错误信息截图
2. 容器日志: `docker logs glxt-api --tail 100`
3. 容器状态: `docker compose ps`

---

## 🎉 部署成功后的下一步

1. **配置域名**（可选）
   - 在域名 DNS 设置中，添加 A 记录指向 139.224.245.244
   - 配置 Nginx 反向代理

2. **配置 HTTPS**（推荐）
   - 使用 Let's Encrypt 免费证书
   - 安装 Certbot

3. **设置自动备份**
   - 数据库定时备份
   - 代码版本控制

4. **配置监控**
   - 安装 Portainer (Docker 可视化管理)
   - 配置日志收集

需要配置这些功能吗？请告诉我！

---

**当前数据库密码**: `Sym89@789Ab`  
**JWT 密钥**: `glxt_Jwt_Secret_Key_2024_Sym89_Production_32Chars_Min`

⚠️ 请妥善保管这些凭证！
