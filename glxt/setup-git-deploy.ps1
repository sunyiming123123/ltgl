# Git Deploy Setup Script
# This script helps you deploy your project using Git

Write-Host "=====================================" -ForegroundColor Green
Write-Host "   Git Deploy Setup" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Step 1: Check Git configuration
Write-Host "[1/6] Checking Git configuration..." -ForegroundColor Yellow

$gitUser = git config user.name
$gitEmail = git config user.email

if ([string]::IsNullOrWhiteSpace($gitUser) -or [string]::IsNullOrWhiteSpace($gitEmail)) {
    Write-Host "  Git user not configured" -ForegroundColor Yellow
    Write-Host ""
    $userName = Read-Host "Enter your name"
    $userEmail = Read-Host "Enter your email"

    git config --global user.name "$userName"
    git config --global user.email "$userEmail"

    Write-Host "  Git user configured" -ForegroundColor Green
} else {
    Write-Host "  Git user: $gitUser <$gitEmail>" -ForegroundColor Green
}

# Step 2: Add files to Git
Write-Host ""
Write-Host "[2/6] Adding files to Git..." -ForegroundColor Yellow

git add .

$status = git status --porcelain
if ($status) {
    Write-Host "  Files added successfully" -ForegroundColor Green
    Write-Host "  Files to commit: $($status.Count) files" -ForegroundColor Gray
} else {
    Write-Host "  No changes to commit" -ForegroundColor Gray
}

# Step 3: Commit changes
Write-Host ""
Write-Host "[3/6] Committing changes..." -ForegroundColor Yellow

$commitMessage = Read-Host "Enter commit message (default: Initial deployment)"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "Initial deployment"
}

git commit -m "$commitMessage"

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Commit successful" -ForegroundColor Green
} else {
    Write-Host "  Nothing to commit or commit failed" -ForegroundColor Yellow
}

# Step 4: Choose Git hosting service
Write-Host ""
Write-Host "[4/6] Choose Git hosting service..." -ForegroundColor Yellow
Write-Host ""
Write-Host "1. GitHub (Global, may be slower in China)" -ForegroundColor White
Write-Host "2. Gitee (Chinese, faster in China) - Recommended" -ForegroundColor Cyan
Write-Host "3. GitLab" -ForegroundColor White
Write-Host "4. Enter custom URL" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter choice (1-4)"

$repoUrl = ""
switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "GitHub Setup:" -ForegroundColor Cyan
        Write-Host "1. Go to: https://github.com/new" -ForegroundColor White
        Write-Host "2. Create a new repository" -ForegroundColor White
        Write-Host "3. Do NOT initialize with README" -ForegroundColor Yellow
        Write-Host ""
        $username = Read-Host "Enter your GitHub username"
        $repoName = Read-Host "Enter repository name (default: glxt)"
        if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = "glxt" }
        $repoUrl = "https://github.com/$username/$repoName.git"
    }
    "2" {
        Write-Host ""
        Write-Host "Gitee Setup:" -ForegroundColor Cyan
        Write-Host "1. Go to: https://gitee.com/projects/new" -ForegroundColor White
        Write-Host "2. Create a new repository" -ForegroundColor White
        Write-Host "3. Do NOT initialize with README" -ForegroundColor Yellow
        Write-Host ""
        $username = Read-Host "Enter your Gitee username"
        $repoName = Read-Host "Enter repository name (default: glxt)"
        if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = "glxt" }
        $repoUrl = "https://gitee.com/$username/$repoName.git"
    }
    "3" {
        Write-Host ""
        Write-Host "GitLab Setup:" -ForegroundColor Cyan
        $username = Read-Host "Enter your GitLab username"
        $repoName = Read-Host "Enter repository name (default: glxt)"
        if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = "glxt" }
        $repoUrl = "https://gitlab.com/$username/$repoName.git"
    }
    "4" {
        $repoUrl = Read-Host "Enter Git repository URL"
    }
    default {
        Write-Host "Invalid choice, using Gitee" -ForegroundColor Yellow
        $username = Read-Host "Enter your Gitee username"
        $repoName = Read-Host "Enter repository name (default: glxt)"
        if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = "glxt" }
        $repoUrl = "https://gitee.com/$username/$repoName.git"
    }
}

Write-Host ""
Write-Host "Repository URL: $repoUrl" -ForegroundColor Cyan

# Step 5: Add remote repository
Write-Host ""
Write-Host "[5/6] Adding remote repository..." -ForegroundColor Yellow

# Check if origin already exists
$existingRemote = git remote get-url origin 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Remote 'origin' already exists: $existingRemote" -ForegroundColor Yellow
    $replace = Read-Host "Replace it? (Y/N)"
    if ($replace -eq "Y" -or $replace -eq "y") {
        git remote remove origin
        git remote add origin $repoUrl
        Write-Host "  Remote updated" -ForegroundColor Green
    }
} else {
    git remote add origin $repoUrl
    Write-Host "  Remote added" -ForegroundColor Green
}

# Step 6: Push to remote
Write-Host ""
Write-Host "[6/6] Pushing to remote repository..." -ForegroundColor Yellow
Write-Host ""
Write-Host "You may need to enter your username and password..." -ForegroundColor Gray
Write-Host ""

# Get current branch name
$branch = git branch --show-current
if ([string]::IsNullOrWhiteSpace($branch)) {
    $branch = "master"
}

git push -u origin $branch

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "   Push Successful!" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository URL: $repoUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Connect to your server via web console:" -ForegroundColor White
    Write-Host "   (Alibaba Cloud / Tencent Cloud / AWS console)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Clone the repository:" -ForegroundColor White
    Write-Host "   git clone $repoUrl /app/glxt" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Deploy:" -ForegroundColor White
    Write-Host "   cd /app/glxt" -ForegroundColor Cyan
    Write-Host "   chmod +x deploy-server.sh" -ForegroundColor Cyan
    Write-Host "   ./deploy-server.sh" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "For detailed instructions, see: .\glxt\GIT_DEPLOY_GUIDE.md" -ForegroundColor Gray
    Write-Host ""

    # Create server deployment commands file
    $serverCommands = @"
# Server Deployment Commands
# Copy these commands and run on your server

# 1. Install Git (if not installed)
# For CentOS/RHEL:
sudo yum install git -y

# For Ubuntu/Debian:
sudo apt update
sudo apt install git -y

# 2. Clone repository
git clone $repoUrl /app/glxt

# 3. Navigate to directory
cd /app/glxt

# 4. Set permissions
chmod +x deploy-server.sh

# 5. Run deployment
./deploy-server.sh
# Select option 1: Build and start services

# 6. View logs
docker compose logs -f

# 7. Check status
docker compose ps

# Access your application at:
# http://YOUR_SERVER_IP:5000
"@

    $serverCommands | Out-File -FilePath "SERVER_COMMANDS.txt" -Encoding UTF8
    Write-Host "Server commands saved to: SERVER_COMMANDS.txt" -ForegroundColor Green
    Write-Host "You can copy these commands to run on your server" -ForegroundColor Gray

} else {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Red
    Write-Host "   Push Failed" -ForegroundColor Red
    Write-Host "=====================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Repository doesn't exist:" -ForegroundColor White
    Write-Host "   - Create the repository on $repoUrl first" -ForegroundColor Gray
    Write-Host "   - Make sure NOT to initialize with README" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Authentication failed:" -ForegroundColor White
    Write-Host "   - Check your username and password" -ForegroundColor Gray
    Write-Host "   - Use personal access token instead of password (GitHub)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Permission denied:" -ForegroundColor White
    Write-Host "   - Make sure you have write access to the repository" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To retry, run this script again" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to exit"
