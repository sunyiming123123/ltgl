# ========================================
# Windows Deploy Script
# Target Server: 139.224.245.244
# ========================================

$SERVER_IP = "139.224.245.244"
$SERVER_USER = "root"
$SERVER_PATH = "/opt/glxt"
$LOCAL_PATH = $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting deployment to cloud server..." -ForegroundColor Cyan
Write-Host "Server: $SERVER_IP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check required files
Write-Host "`n>>> [1/5] Checking required files..." -ForegroundColor Yellow
$requiredFiles = @(
    "Dockerfile",
    "docker-compose.yml",
    "glxt.csproj"
)

foreach ($file in $requiredFiles) {
    $filePath = Join-Path $LOCAL_PATH $file
    if (-Not (Test-Path $filePath)) {
        Write-Host "ERROR: Missing file: $file" -ForegroundColor Red
        exit 1
    }
}
Write-Host "OK: All required files exist" -ForegroundColor Green

# Upload server setup script
Write-Host "`n>>> [2/5] Uploading server setup script..." -ForegroundColor Yellow
scp "$LOCAL_PATH\server-setup.sh" "${SERVER_USER}@${SERVER_IP}:/tmp/server-setup.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Upload failed. Please check SSH connection" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Script uploaded successfully" -ForegroundColor Green

# Run installation script on server
Write-Host "`n>>> [3/5] Installing Docker on server..." -ForegroundColor Yellow
Write-Host "(This may take a few minutes...)" -ForegroundColor Gray
ssh "${SERVER_USER}@${SERVER_IP}" "chmod +x /tmp/server-setup.sh && /tmp/server-setup.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker installation failed" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Docker installed successfully" -ForegroundColor Green

# Upload project files
Write-Host "`n>>> [4/5] Uploading project files to server..." -ForegroundColor Yellow
Write-Host "(This may take a few minutes...)" -ForegroundColor Gray

scp -r "$LOCAL_PATH\*" "${SERVER_USER}@${SERVER_IP}:${SERVER_PATH}/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: File upload failed" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Project files uploaded successfully" -ForegroundColor Green

# Start Docker containers
Write-Host "`n>>> [5/5] Starting Docker containers..." -ForegroundColor Yellow
Write-Host "(First run needs to download images, may take 5-10 minutes...)" -ForegroundColor Gray
ssh "${SERVER_USER}@${SERVER_IP}" "cd ${SERVER_PATH} && docker compose up -d --build"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Container startup failed" -ForegroundColor Red
    Write-Host "View logs: ssh ${SERVER_USER}@${SERVER_IP} 'docker logs glxt-api'" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK: Containers started successfully" -ForegroundColor Green

# Wait for SQL Server
Write-Host "`n>>> Waiting for SQL Server to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Run database migration
Write-Host "`n>>> Running database migration..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" "docker exec glxt-api dotnet ef database update"
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Database migration may have failed, please check manually" -ForegroundColor Yellow
} else {
    Write-Host "OK: Database migration completed" -ForegroundColor Green
}

# Check container status
Write-Host "`n>>> Checking container status..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" "docker compose -f ${SERVER_PATH}/docker-compose.yml ps"

# Done
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "API URL: http://${SERVER_IP}:5000" -ForegroundColor Cyan
Write-Host "`nView logs: ssh ${SERVER_USER}@${SERVER_IP} 'docker logs glxt-api -f'" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Green
