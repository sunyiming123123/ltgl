#!/bin/bash

##############################################
# GLXT 一键部署脚本 - Alibaba Cloud Linux 3
# 使用方法: bash deploy.sh
##############################################

set -e  # 遇到错误立即退出

echo "========================================="
echo "  GLXT 项目一键部署"
echo "========================================="

# 1. 检查并安装 Docker
if ! command -v docker &> /dev/null; then
    echo "📦 正在安装 Docker..."
    sudo yum update -y
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "✅ Docker 安装完成"
else
    echo "✅ Docker 已安装"
fi

# 2. 检查并安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "📦 正在安装 Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose 安装完成"
else
    echo "✅ Docker Compose 已安装"
fi

# 3. 停止并删除旧容器（如果存在）
echo "🔄 清理旧容器..."
docker-compose down 2>/dev/null || true

# 4. 拉取最新代码（如果是 Git 仓库）
if [ -d ".git" ]; then
    echo "📥 拉取最新代码..."
    git pull origin master
fi

# 5. 构建并启动容器
echo "🚀 构建并启动服务..."
docker-compose up -d --build

# 6. 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 7. 检查服务状态
echo ""
echo "========================================="
echo "  部署完成！服务状态："
echo "========================================="
docker-compose ps

# 8. 显示日志
echo ""
echo "📋 最近日志："
docker-compose logs --tail=20

echo ""
echo "========================================="
echo "  ✅ 部署成功！"
echo "========================================="
echo "🌐 访问地址: http://你的服务器IP:5000"
echo ""
echo "📌 常用命令："
echo "  查看日志: docker-compose logs -f"
echo "  停止服务: docker-compose stop"
echo "  启动服务: docker-compose start"
echo "  重启服务: docker-compose restart"
echo "  卸载服务: docker-compose down"
echo "========================================="
