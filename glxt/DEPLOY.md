# GLXT 部署指南 - 阿里云 Alibaba Cloud Linux 3

## 🚀 最简单的部署方式（一键部署）

### 第一步：连接到服务器

```bash
ssh root@你的服务器IP
```

### 第二步：克隆项目

```bash
# 首次部署
git clone https://gitee.com/19145960820/GLXT.git
cd GLXT/glxt
```

### 第三步：执行一键部署脚本

```bash
# 给脚本执行权限
chmod +x deploy.sh

# 运行一键部署
bash deploy.sh
```

**就这么简单！** 脚本会自动：
- ✅ 安装 Docker 和 Docker Compose
- ✅ 构建项目镜像
- ✅ 启动所有服务（Web API + SQL Server）
- ✅ 显示服务状态和日志

---

## 📋 部署后操作

### 1. 开放端口（阿里云安全组）

登录 [阿里云控制台](https://ecs.console.aliyun.com/) → 安全组 → 配置规则：

| 端口范围 | 授权对象 | 说明 |
|---------|---------|------|
| 5000/5000 | 0.0.0.0/0 | HTTP 访问 |
| 5001/5001 | 0.0.0.0/0 | HTTPS 访问 |
| 1433/1433 | 0.0.0.0/0 | SQL Server（可选，仅测试时开放）|

### 2. 访问应用

```
http://你的服务器IP:5000
```

---

## 🔧 常用命令

```bash
# 查看实时日志
docker-compose logs -f

# 查看 API 日志
docker-compose logs -f glxt-api

# 重启服务
docker-compose restart

# 停止服务
docker-compose stop

# 启动服务
docker-compose start

# 完全卸载
docker-compose down -v
```

---

## 🔄 更新部署

当代码有更新时：

```bash
# 进入项目目录
cd /root/GLXT/glxt

# 重新运行部署脚本
bash deploy.sh
```

就这么简单！脚本会自动拉取最新代码并重新部署。

---

## 🐛 故障排查

### 查看服务状态
```bash
docker-compose ps
```

### 查看详细日志
```bash
docker-compose logs --tail=100
```

### 重新构建
```bash
docker-compose down
docker-compose up -d --build --force-recreate
```

### 进入容器调试
```bash
# 进入 API 容器
docker exec -it glxt-api bash

# 进入数据库容器
docker exec -it glxt-sqlserver bash
```

---

## 📦 包含的服务

- **glxt-api**: Web API 服务（端口 5000, 5001）
- **glxt-sqlserver**: SQL Server 2022 Express（端口 1433）

---

## ⚠️ 生产环境建议

1. **修改数据库密码**: 编辑 `docker-compose.yml` 中的 `SA_PASSWORD`
2. **使用 HTTPS**: 配置 SSL 证书
3. **备份数据库**: 定期备份 SQL Server 数据
4. **限制端口访问**: 仅开放必要端口给特定IP

---

## 💡 提示

- 首次启动需要下载镜像，可能需要几分钟
- SQL Server 需要至少 2GB 内存
- 数据持久化在 Docker volume 中，重启不会丢失数据

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
