#!/bin/bash
# ============================================
# GLXT Simple Deploy Script
# Run this script ON THE SERVER directly
# ============================================

set -e

echo "========================================="
echo "  GLXT Deployment Script"
echo "========================================="
echo ""

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "[1/6] Installing Docker..."
    sudo yum update -y
    sudo yum install -y docker git
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "[OK] Docker installed"
else
    echo "[OK] Docker already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "[2/6] Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "[OK] Docker Compose installed"
else
    echo "[OK] Docker Compose already installed"
fi

# Clone or update project
echo "[3/6] Preparing project..."
cd ~
if [ -d "GLXT" ]; then
    echo "Updating existing project..."
    cd GLXT
    git pull origin master
else
    echo "Cloning project..."
    git clone https://gitee.com/19145960820/GLXT.git
    cd GLXT
fi

# Enter project directory
cd glxt

# Stop old containers
echo "[4/6] Stopping old containers..."
docker-compose down 2>/dev/null || true

# Build and start
echo "[5/6] Building and starting services..."
docker-compose up -d --build

# Wait for startup
echo "[6/6] Waiting for services to start..."
sleep 15

# Show status
echo ""
echo "========================================="
echo "  Deployment Completed!"
echo "========================================="
echo ""
docker-compose ps
echo ""
echo "Recent logs:"
docker-compose logs --tail=20
echo ""
echo "========================================="
echo "  [SUCCESS] Your app is running!"
echo "========================================="
echo ""
echo "Access URL: http://$(curl -s ifconfig.me):5000"
echo ""
echo "Common commands:"
echo "  cd ~/GLXT/glxt"
echo "  docker-compose logs -f     # View logs"
echo "  docker-compose restart     # Restart"
echo "  docker-compose ps          # Status"
echo "  docker-compose down        # Stop all"
echo ""
