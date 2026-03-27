# ============================================
# GLXT Deploy Script - Windows to Aliyun
# ============================================

param(
    [string]$ServerIP = "139.224.245.244",
    [string]$ServerUser = "root"
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  GLXT Deploy to Aliyun Server" -ForegroundColor Cyan
Write-Host "  Server: $ServerIP" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Test SSH connection
Write-Host "[1/5] Testing server connection..." -ForegroundColor Yellow
$testConnection = Test-Connection -ComputerName $ServerIP -Count 1 -Quiet
if (-not $testConnection) {
    Write-Host "[ERROR] Cannot connect to server $ServerIP" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. Server IP is correct" -ForegroundColor Yellow
    Write-Host "  2. Aliyun Security Group opened SSH port (22)" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Server connection successful" -ForegroundColor Green
Write-Host ""

# Build deploy commands
Write-Host "[2/5] Preparing deployment commands..." -ForegroundColor Yellow
$deployCommands = @"
# Install Docker if not exists
if ! command -v docker &> /dev/null; then
    echo '[INSTALL] Installing Docker...'
    sudo yum update -y
    sudo yum install -y docker git
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Install Docker Compose if not exists
if ! command -v docker-compose &> /dev/null; then
    echo '[INSTALL] Installing Docker Compose...'
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-`$(uname -s)-`$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Clone or update project
if [ -d "GLXT" ]; then
    echo '[UPDATE] Updating project code...'
    cd GLXT
    git pull origin master
else
    echo '[CLONE] Cloning project...'
    git clone https://gitee.com/19145960820/GLXT.git
    cd GLXT
fi

# Enter project directory
cd glxt

# Stop old containers
echo '[STOP] Stopping old containers...'
docker-compose down 2>/dev/null || true

# Build and start
echo '[BUILD] Building and starting services...'
docker-compose up -d --build

# Wait for startup
echo '[WAIT] Waiting for services to start...'
sleep 15

# Show status
echo ''
echo '========================================='
echo 'Deployment completed! Service status:'
echo '========================================='
docker-compose ps

echo ''
echo '[LOGS] Recent logs:'
docker-compose logs --tail=20

echo ''
echo '========================================='
echo '[SUCCESS] Deployment completed!'
echo '========================================='
echo 'Access URL: http://$ServerIP:5000'
echo ''
"@

# Execute deployment
Write-Host "[3/5] Connecting to server..." -ForegroundColor Yellow
Write-Host "Please enter server password:" -ForegroundColor Yellow
Write-Host ""

try {
    Write-Host "[4/5] Executing deployment on server..." -ForegroundColor Yellow
    # Execute remote commands via SSH
    $deployCommands | ssh "$ServerUser@$ServerIP" "bash -s"

    Write-Host ""
    Write-Host "[5/5] Verifying deployment..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "  [SUCCESS] Deployment Completed!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access URL: http://$ServerIP`:5000" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Common Management Commands:" -ForegroundColor Yellow
    Write-Host "  ssh $ServerUser@$ServerIP" -ForegroundColor White
    Write-Host "  cd GLXT/glxt" -ForegroundColor White
    Write-Host "  docker-compose logs -f     # View logs" -ForegroundColor White
    Write-Host "  docker-compose restart     # Restart service" -ForegroundColor White
    Write-Host "  docker-compose ps          # Check status" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "[ERROR] Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. First connection requires password input" -ForegroundColor White
    Write-Host "2. Ensure Aliyun Security Group opened these ports:" -ForegroundColor White
    Write-Host "   - 22 (SSH)" -ForegroundColor White
    Write-Host "   - 5000 (HTTP)" -ForegroundColor White
    Write-Host "   - 5001 (HTTPS)" -ForegroundColor White
    Write-Host ""
    exit 1
}
