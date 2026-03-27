#!/bin/bash
# ========================================
# 阿里云服务器 Docker 自动化部署脚本
# 服务器: 139.224.245.244
# 系统: Alibaba Cloud Linux 3
# ========================================

set -e  # 遇到错误立即退出

echo "=========================================="
echo "开始安装 Docker 和部署应用..."
echo "=========================================="

# 1. 更新系统
echo ">>> [1/8] 更新系统包..."
sudo yum update -y

# 2. 安装必要工具
echo ">>> [2/8] 安装必要工具..."
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 git curl

# 3. 添加 Docker 仓库
echo ">>> [3/8] 配置 Docker 仓库..."
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 4. 安装 Docker
echo ">>> [4/8] 安装 Docker..."
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 5. 启动 Docker
echo ">>> [5/8] 启动 Docker 服务..."
sudo systemctl start docker
sudo systemctl enable docker

# 6. 验证 Docker 安装
echo ">>> [6/8] 验证 Docker 安装..."
docker --version
docker compose version

# 7. 配置防火墙
echo ">>> [7/8] 配置防火墙规则..."
if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=5000/tcp
    sudo firewall-cmd --permanent --add-port=1433/tcp
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --reload
    echo "防火墙规则已配置"
else
    echo "未检测到 firewalld，跳过防火墙配置"
fi

# 8. 创建项目目录
echo ">>> [8/8] 创建项目目录..."
sudo mkdir -p /opt/glxt
sudo chown -R $(whoami):$(whoami) /opt/glxt

echo ""
echo "=========================================="
echo "✅ Docker 安装完成！"
echo "=========================================="
echo "Docker 版本: $(docker --version)"
echo "Docker Compose 版本: $(docker compose version)"
echo "项目目录: /opt/glxt"
echo ""
echo "下一步: 上传项目文件到 /opt/glxt"
echo "=========================================="
