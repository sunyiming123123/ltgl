# Upload Project to Server Script
# Usage: .\upload-to-server.ps1

param(
    [string]$ServerIP = "",
    [string]$ServerUser = "root",
    [string]$ServerPath = "/app/glxt"
)

Write-Host "=====================================" -ForegroundColor Green
Write-Host "   Upload Project to Cloud Server" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Ask for server IP if not provided
if ([string]::IsNullOrWhiteSpace($ServerIP)) {
    $ServerIP = Read-Host "Please enter server IP address"
}

if ([string]::IsNullOrWhiteSpace($ServerUser)) {
    $ServerUser = Read-Host "Please enter server username (default: root)"
    if ([string]::IsNullOrWhiteSpace($ServerUser)) {
        $ServerUser = "root"
    }
}

if ([string]::IsNullOrWhiteSpace($ServerPath)) {
    $ServerPath = Read-Host "Please enter server deploy path (default: /app/glxt)"
    if ([string]::IsNullOrWhiteSpace($ServerPath)) {
        $ServerPath = "/app/glxt"
    }
}

Write-Host ""
Write-Host "Upload Configuration:" -ForegroundColor Cyan
Write-Host "  Server: $ServerUser@$ServerIP" -ForegroundColor White
Write-Host "  Path:   $ServerPath" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Confirm upload? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Operation cancelled" -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host "   Starting Upload" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host ""

try {
    # Step 1: Compress project files
    Write-Host "[1/4] Compressing project files..." -ForegroundColor Yellow

    $sourceDir = ".\glxt"
    $zipFile = "glxt-deploy.zip"

    # Remove old zip file
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
    }

    Write-Host "  Compressing..." -ForegroundColor Gray
    Compress-Archive -Path "$sourceDir\*" -DestinationPath $zipFile -Force

    $zipSize = (Get-Item $zipFile).Length / 1MB
    Write-Host "  Done (Size: $([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green

    # Step 2: Prepare server environment
    Write-Host ""
    Write-Host "[2/4] Preparing server environment..." -ForegroundColor Yellow

    $sshCommand = "mkdir -p $ServerPath; cd $ServerPath"

    Write-Host "  Creating directory: $ServerPath" -ForegroundColor Gray
    ssh "$ServerUser@$ServerIP" $sshCommand

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Server environment prepared" -ForegroundColor Green
    } else {
        Write-Host "  SSH connection failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please check:" -ForegroundColor Yellow
        Write-Host "  1. Is the server IP address correct?" -ForegroundColor White
        Write-Host "  2. Is SSH key authentication configured?" -ForegroundColor White
        Write-Host "  3. Does the server allow SSH connections?" -ForegroundColor White
        exit 1
    }

    # Step 3: Upload files
    Write-Host ""
    Write-Host "[3/4] Uploading files to server..." -ForegroundColor Yellow
    Write-Host "  Target: $ServerUser@$ServerIP`:$ServerPath/" -ForegroundColor Gray

    scp $zipFile "$ServerUser@$ServerIP`:$ServerPath/"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  File upload successful" -ForegroundColor Green
    } else {
        Write-Host "  File upload failed" -ForegroundColor Red
        exit 1
    }

    # Step 4: Extract and deploy on server
    Write-Host ""
    Write-Host "[4/4] Deploying on server..." -ForegroundColor Yellow

    $deployCommand = @"
cd $ServerPath
echo "Extracting files..."
unzip -o glxt-deploy.zip
echo "Setting permissions..."
chmod +x deploy-server.sh
echo "Deployment completed!"
echo ""
echo "Project uploaded to: $ServerPath"
echo ""
echo "Next steps:"
echo "  cd $ServerPath"
echo "  ./deploy-server.sh"
"@

    ssh "$ServerUser@$ServerIP" $deployCommand

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "   Upload Completed!" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Project uploaded to server: $ServerPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. SSH to server:" -ForegroundColor White
        Write-Host "   ssh $ServerUser@$ServerIP" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Go to project directory:" -ForegroundColor White
        Write-Host "   cd $ServerPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "3. Run deployment script:" -ForegroundColor White
        Write-Host "   ./deploy-server.sh" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Or execute directly:" -ForegroundColor Yellow
        Write-Host "   ssh $ServerUser@$ServerIP `"cd $ServerPath; ./deploy-server.sh`"" -ForegroundColor Gray
        Write-Host ""

        # Ask if deploy now
        $deployNow = Read-Host "Deploy on server now? (Y/N)"
        if ($deployNow -eq "Y" -or $deployNow -eq "y") {
            Write-Host ""
            Write-Host "Starting deployment on server..." -ForegroundColor Yellow
            Write-Host ""
            ssh -t "$ServerUser@$ServerIP" "cd $ServerPath; ./deploy-server.sh"
        }
    } else {
        Write-Host "  Server deployment failed" -ForegroundColor Red
        exit 1
    }

} catch {
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clean up temp files
    if (Test-Path $zipFile) {
        Write-Host ""
        Write-Host "Cleaning up temporary files..." -ForegroundColor Gray
        Remove-Item $zipFile -Force
    }
}

Write-Host ""
Read-Host "Press any key to exit"
