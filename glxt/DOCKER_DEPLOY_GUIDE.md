# Docker 部署指南

## 前置要求

1. **安装 Docker Desktop**
   - 下载地址：https://www.docker.com/products/docker-desktop/
   - 安装后重启电脑
   - 启动 Docker Desktop 并确保 Docker 服务正在运行

2. **注册 Docker Hub 账号**（如果还没有）
   - 注册地址：https://hub.docker.com/signup

## 部署步骤

### 步骤 1: 构建 Docker 镜像

在项目根目录（`D:\test\glxt\`）下打开 PowerShell 或命令提示符，执行：

```bash
# 进入 glxt 目录
cd glxt

# 构建 Docker 镜像
docker build -t glxt-app:latest .
```

或者从根目录执行：

```bash
# 从根目录构建
docker build -t glxt-app:latest -f glxt\Dockerfile glxt
```

### 步骤 2: 测试镜像（本地运行）

```bash
# 运行容器进行测试
docker run -d -p 8080:8080 --name glxt-test glxt-app:latest

# 查看运行状态
docker ps

# 查看日志
docker logs glxt-test

# 测试完成后停止并删除容器
docker stop glxt-test
docker rm glxt-test
```

访问 http://localhost:8080 测试应用是否正常运行。

### 步骤 3: 登录 Docker Hub

```bash
# 登录 Docker Hub
docker login

# 输入您的 Docker Hub 用户名和密码
```

### 步骤 4: 标记镜像

将镜像标记为可以推送到 Docker Hub 的格式：

```bash
# 格式：docker tag 本地镜像名:标签 docker用户名/镜像名:标签
docker tag glxt-app:latest your-dockerhub-username/glxt-app:latest

# 示例（请替换 your-dockerhub-username 为您的实际用户名）：
# docker tag glxt-app:latest johndoe/glxt-app:latest
```

### 步骤 5: 推送镜像到 Docker Hub

```bash
# 推送镜像
docker push your-dockerhub-username/glxt-app:latest

# 示例：
# docker push johndoe/glxt-app:latest
```

### 步骤 6: 验证上传

访问 https://hub.docker.com/repositories 查看您上传的镜像。

## 在服务器上部署

### 方式 1: 直接运行容器

在目标服务器上拉取并运行：

```bash
# 拉取镜像
docker pull your-dockerhub-username/glxt-app:latest

# 运行容器
docker run -d \
  -p 8080:8080 \
  --name glxt-app \
  --restart unless-stopped \
  your-dockerhub-username/glxt-app:latest
```

### 方式 2: 使用 Docker Compose（推荐）

创建 `docker-compose.yml` 文件（已在下方提供），然后：

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 环境变量配置

如果需要覆盖配置（如数据库连接字符串），可以使用环境变量：

```bash
docker run -d \
  -p 8080:8080 \
  -e ConnectionStrings__DefaultConnection="Server=your-db;Database=glxt;User=user;Password=pass;" \
  -e JwtSettings__Secret="your-new-secret-key" \
  --name glxt-app \
  your-dockerhub-username/glxt-app:latest
```

## 常用 Docker 命令

```bash
# 查看所有镜像
docker images

# 查看运行中的容器
docker ps

# 查看所有容器（包括停止的）
docker ps -a

# 查看容器日志
docker logs glxt-app

# 进入容器内部
docker exec -it glxt-app /bin/bash

# 停止容器
docker stop glxt-app

# 启动容器
docker start glxt-app

# 删除容器
docker rm glxt-app

# 删除镜像
docker rmi glxt-app:latest

# 清理未使用的资源
docker system prune -a
```

## 故障排查

### 问题 1: 容器启动后立即退出

```bash
# 查看容器日志
docker logs glxt-app

# 常见原因：
# - 数据库连接失败
# - 端口被占用
# - 配置文件错误
```

### 问题 2: 无法访问应用

- 检查防火墙设置
- 确认端口映射正确
- 检查容器是否正在运行：`docker ps`

### 问题 3: 数据库连接失败

如果数据库在其他容器中，使用 Docker 网络连接：

```bash
# 创建网络
docker network create glxt-network

# 在同一网络中运行容器
docker run -d --network glxt-network --name glxt-app ...
```

## 安全建议

1. **不要在镜像中硬编码敏感信息**
   - 使用环境变量传递敏感配置
   - 考虑使用 Docker Secrets 或配置管理工具

2. **定期更新基础镜像**
   ```bash
   # 重新构建镜像以获取安全更新
   docker build --no-cache -t glxt-app:latest .
   ```

3. **限制容器权限**
   - 避免以 root 用户运行
   - 使用只读文件系统

## 下一步

1. 安装 Docker Desktop
2. 按照上述步骤构建和推送镜像
3. 在服务器上部署应用
4. 配置反向代理（如 Nginx）
5. 配置 HTTPS 证书

## 相关文件

- `Dockerfile` - Docker 构建配置
- `.dockerignore` - 忽略文件配置
- `docker-compose.yml` - Docker Compose 配置（见下方）
