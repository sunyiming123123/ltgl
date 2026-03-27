# Docker 部署指南

## 📋 前置要求

- Docker Desktop 或 Docker Engine (20.10+)
- Docker Compose (2.0+)

## 🚀 快速启动

### 1. 构建并启动所有服务

```bash
# 进入项目目录
cd glxt

# 构建并启动容器
docker-compose up -d --build
```

### 2. 查看容器状态

```bash
docker-compose ps
```

### 3. 运行数据库迁移

**Windows (PowerShell):**
```powershell
docker exec -it glxt-api dotnet ef database update
```

**Linux/Mac:**
```bash
chmod +x init-db.sh
./init-db.sh
```

**或者手动执行:**
```bash
docker exec -it glxt-api dotnet ef database update
```

### 4. 查看日志

```bash
# 查看 API 日志
docker logs glxt-api -f

# 查看 SQL Server 日志
docker logs glxt-sqlserver -f

# 查看所有服务日志
docker-compose logs -f
```

## 🌐 访问应用

- **API 端点**: http://localhost:5000
- **Swagger 文档**: http://localhost:5000/swagger
- **SQL Server**: localhost:1433
  - 用户名: `sa`
  - 密码: `YourStrong@Password123`

## 🔧 常用命令

### 停止服务
```bash
docker-compose down
```

### 停止并删除数据
```bash
docker-compose down -v
```

### 重新构建镜像
```bash
docker-compose build --no-cache
```

### 进入容器 Shell
```bash
# 进入 API 容器
docker exec -it glxt-api /bin/bash

# 进入 SQL Server 容器
docker exec -it glxt-sqlserver /bin/bash
```

### 查看数据库
```bash
docker exec -it glxt-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong@Password123
```

## 🔐 安全配置

### ⚠️ 生产环境必须修改的配置

在 `docker-compose.yml` 中修改以下内容：

1. **SQL Server 密码**
   ```yaml
   - SA_PASSWORD=YourStrong@Password123  # 改成强密码
   ```

2. **JWT 密钥**
   ```yaml
   - Jwt__Key=YourSuperSecretKeyHere...  # 改成随机生成的密钥
   ```

3. **数据库连接字符串**
   ```yaml
   - ConnectionStrings__DefaultConnection=...Password=YourStrong@Password123...  # 密码要匹配
   ```

### 生成强密钥

**PowerShell:**
```powershell
[Convert]::ToBase64String((1..64 | ForEach-Object { Get-Random -Maximum 256 }))
```

**Linux/Mac:**
```bash
openssl rand -base64 64
```

## 📦 单独构建 Docker 镜像

如果只需要构建 API 镜像（不使用 docker-compose）：

```bash
# 构建镜像
docker build -t glxt-api:latest .

# 运行容器
docker run -d \
  --name glxt-api \
  -p 5000:8080 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e ConnectionStrings__DefaultConnection="Server=your-sql-server;Database=GlxtDb;..." \
  glxt-api:latest
```

## 🔄 更新应用

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose up -d --build

# 运行数据库迁移
docker exec -it glxt-api dotnet ef database update
```

## 🐛 故障排除

### 1. 容器无法启动
```bash
# 查看详细日志
docker-compose logs glxt-api
```

### 2. 数据库连接失败
- 确保 SQL Server 容器已启动: `docker ps`
- 检查连接字符串中的密码是否正确
- 等待 SQL Server 完全启动（约 20-30 秒）

### 3. 端口冲突
如果 5000 或 1433 端口被占用，修改 `docker-compose.yml` 中的端口映射：
```yaml
ports:
  - "5002:8080"  # 改成其他端口
```

### 4. 数据迁移失败
```bash
# 进入容器手动检查
docker exec -it glxt-api /bin/bash
dotnet ef migrations list
dotnet ef database update --verbose
```

## 📊 监控和健康检查

### 健康检查端点

添加到 `Program.cs`:
```csharp
app.MapHealthChecks("/health");
```

### 检查容器健康状态
```bash
docker inspect glxt-api --format='{{.State.Health.Status}}'
```

## 🌍 环境变量说明

| 变量名 | 说明 | 示例值 |
|--------|------|--------|
| `ASPNETCORE_ENVIRONMENT` | 运行环境 | Production, Development |
| `ConnectionStrings__DefaultConnection` | 数据库连接 | Server=sqlserver;... |
| `Jwt__Key` | JWT 签名密钥 | 至少32字符 |
| `Jwt__Issuer` | JWT 发行者 | GlxtApi |
| `Jwt__Audience` | JWT 受众 | GlxtClient |
| `Jwt__ExpireMinutes` | Token 过期时间 | 60 |

## 📝 备份和恢复

### 备份数据库
```bash
docker exec glxt-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P YourStrong@Password123 \
  -Q "BACKUP DATABASE [GlxtDb] TO DISK = N'/var/opt/mssql/backup/GlxtDb.bak'"

docker cp glxt-sqlserver:/var/opt/mssql/backup/GlxtDb.bak ./backup/
```

### 恢复数据库
```bash
docker cp ./backup/GlxtDb.bak glxt-sqlserver:/var/opt/mssql/backup/

docker exec glxt-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P YourStrong@Password123 \
  -Q "RESTORE DATABASE [GlxtDb] FROM DISK = N'/var/opt/mssql/backup/GlxtDb.bak'"
```

## 🎯 测试部署

### 测试注册
```bash
curl -X POST http://localhost:5000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Test@123456",
    "fullName": "Test User"
  }'
```

### 测试登录
```bash
curl -X POST http://localhost:5000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "Test@123456"
  }'
```

## 📚 更多资源

- [Docker 官方文档](https://docs.docker.com/)
- [.NET Docker 镜像](https://hub.docker.com/_/microsoft-dotnet)
- [SQL Server Docker 镜像](https://hub.docker.com/_/microsoft-mssql-server)
