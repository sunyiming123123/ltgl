# Docker 快速命令参考

## 🚀 快速开始

### 方法 1: 使用部署脚本（推荐）
```powershell
# 在 glxt 目录下运行
.\deploy-docker.ps1
```

### 方法 2: 手动执行命令

#### 步骤 1: 构建镜像
```bash
docker build -t glxt-app:latest .
```

#### 步骤 2: 登录 Docker Hub
```bash
docker login
# 输入用户名和密码
```

#### 步骤 3: 标记镜像
```bash
# 替换 YOUR_USERNAME 为您的 Docker Hub 用户名
docker tag glxt-app:latest YOUR_USERNAME/glxt-app:latest
```

#### 步骤 4: 推送到 Docker Hub
```bash
docker push YOUR_USERNAME/glxt-app:latest
```

---

## 📦 本地测试

### 使用 Docker Compose（推荐）
```bash
# 启动所有服务（包括数据库）
docker-compose up -d

# 查看日志
docker-compose logs -f

# 查看运行状态
docker-compose ps

# 停止服务
docker-compose down

# 停止服务并删除数据
docker-compose down -v
```

### 直接运行单个容器
```bash
# 运行应用
docker run -d \
  -p 8080:8080 \
  --name glxt-app \
  glxt-app:latest

# 查看日志
docker logs glxt-app

# 停止容器
docker stop glxt-app

# 删除容器
docker rm glxt-app
```

---

## 🌐 在服务器上部署

### 从 Docker Hub 拉取并运行
```bash
# 拉取镜像
docker pull YOUR_USERNAME/glxt-app:latest

# 运行容器
docker run -d \
  -p 8080:8080 \
  -e ConnectionStrings__DefaultConnection="Server=your-db;Database=glxt;User=user;Password=pass;" \
  --name glxt-app \
  --restart unless-stopped \
  YOUR_USERNAME/glxt-app:latest
```

### 使用 Docker Compose
```bash
# 1. 上传 docker-compose.yml 到服务器
# 2. 修改配置（数据库连接等）
# 3. 启动服务
docker-compose up -d
```

---

## 🔧 常用管理命令

### 查看信息
```bash
# 查看所有镜像
docker images

# 查看运行中的容器
docker ps

# 查看所有容器
docker ps -a

# 查看容器日志
docker logs glxt-app

# 实时查看日志
docker logs -f glxt-app

# 查看容器资源使用
docker stats glxt-app
```

### 容器操作
```bash
# 启动容器
docker start glxt-app

# 停止容器
docker stop glxt-app

# 重启容器
docker restart glxt-app

# 进入容器
docker exec -it glxt-app /bin/bash

# 删除容器
docker rm glxt-app

# 强制删除运行中的容器
docker rm -f glxt-app
```

### 镜像操作
```bash
# 删除镜像
docker rmi glxt-app:latest

# 删除未使用的镜像
docker image prune

# 查看镜像详情
docker inspect glxt-app:latest
```

### 清理命令
```bash
# 清理停止的容器
docker container prune

# 清理未使用的镜像
docker image prune -a

# 清理未使用的卷
docker volume prune

# 清理所有未使用的资源
docker system prune -a --volumes
```

---

## 🐛 故障排查

### 查看容器为何退出
```bash
docker logs glxt-app
docker inspect glxt-app
```

### 检查端口占用
```bash
# Windows
netstat -ano | findstr :8080

# Linux
netstat -tlnp | grep 8080
```

### 测试容器内网络
```bash
docker exec glxt-app curl http://localhost:8080
```

### 查看容器环境变量
```bash
docker exec glxt-app printenv
```

---

## 🔐 环境变量配置

运行时覆盖配置：

```bash
docker run -d \
  -p 8080:8080 \
  -e ConnectionStrings__DefaultConnection="Server=db;Database=glxt;User=user;Password=pass;" \
  -e JwtSettings__Secret="your-secret-key" \
  -e JwtSettings__Issuer="glxt-api" \
  -e JwtSettings__Audience="glxt-users" \
  -e JwtSettings__ExpireMinutes="60" \
  -e ASPNETCORE_ENVIRONMENT="Production" \
  --name glxt-app \
  glxt-app:latest
```

---

## 📊 监控和健康检查

### 添加健康检查
```bash
docker run -d \
  --health-cmd="curl -f http://localhost:8080/health || exit 1" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  -p 8080:8080 \
  --name glxt-app \
  glxt-app:latest
```

### 查看健康状态
```bash
docker inspect --format='{{.State.Health.Status}}' glxt-app
```

---

## 🔄 更新部署

### 更新到新版本
```bash
# 1. 构建新镜像
docker build -t glxt-app:v2.0 .

# 2. 停止旧容器
docker stop glxt-app
docker rm glxt-app

# 3. 运行新容器
docker run -d -p 8080:8080 --name glxt-app glxt-app:v2.0
```

### 使用 Docker Compose 更新
```bash
# 拉取最新代码后
docker-compose build
docker-compose up -d
```

---

## 📝 最佳实践

1. **使用版本标签**
   ```bash
   docker build -t glxt-app:v1.0.0 .
   docker tag glxt-app:v1.0.0 glxt-app:latest
   ```

2. **使用 .env 文件管理环境变量**
   ```bash
   # 创建 .env 文件
   echo "DB_HOST=localhost" > .env
   echo "DB_USER=admin" >> .env

   # 使用 .env 文件
   docker run --env-file .env glxt-app:latest
   ```

3. **定期清理**
   ```bash
   # 每周执行一次
   docker system prune -a --volumes
   ```

4. **备份数据卷**
   ```bash
   docker run --rm \
     -v sqlserver-data:/data \
     -v $(pwd):/backup \
     alpine tar czf /backup/db-backup.tar.gz /data
   ```

---

## 🆘 获取帮助

```bash
# Docker 命令帮助
docker --help
docker build --help
docker run --help

# Docker Compose 帮助
docker-compose --help
```

---

## 📚 相关资源

- Docker 官方文档: https://docs.docker.com/
- Docker Hub: https://hub.docker.com/
- .NET Docker 镜像: https://hub.docker.com/_/microsoft-dotnet
