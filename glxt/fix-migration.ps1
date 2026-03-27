# EF Core Migration Fix Script
# Usage: .\fix-migration.ps1

Write-Host "=== Starting EF Core Migration Fix ===" -ForegroundColor Green

$projectPath = "D:\test\glxt"
Set-Location $projectPath

# Step 1: Check EF Core Tools
Write-Host "`n[1/6] Checking EF Core Tools..." -ForegroundColor Yellow
try {
    $efVersion = dotnet ef --version 2>&1
    Write-Host "  Current version: $efVersion" -ForegroundColor Gray
} catch {
    Write-Host "  Installing EF Core tools..." -ForegroundColor Gray
    dotnet tool install --global dotnet-ef
}

# Step 2: Clean Project
Write-Host "`n[2/6] Cleaning project..." -ForegroundColor Yellow
dotnet clean glxt\glxt.csproj
Write-Host "  Done" -ForegroundColor Green

# Step 3: Restore NuGet Packages
Write-Host "`n[3/6] Restoring NuGet packages..." -ForegroundColor Yellow
dotnet restore glxt\glxt.csproj
Write-Host "  Done" -ForegroundColor Green

# Step 4: Build Project
Write-Host "`n[4/6] Building project..." -ForegroundColor Yellow
dotnet build glxt\glxt.csproj --no-incremental
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "  Build successful" -ForegroundColor Green

# Step 5: Check Existing Migrations
Write-Host "`n[5/6] Checking existing migrations..." -ForegroundColor Yellow
$migrationsPath = "glxt\Migrations"
if (Test-Path $migrationsPath) {
    $response = Read-Host "  Found existing migrations. Delete? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Remove-Item -Path $migrationsPath -Recurse -Force
        Write-Host "  Deleted old migrations" -ForegroundColor Green
    }
} else {
    Write-Host "  No existing migrations" -ForegroundColor Green
}

# Step 6: Create New Migration
Write-Host "`n[6/6] Creating new migration..." -ForegroundColor Yellow
Write-Host "  Running: dotnet ef migrations add AddChatFeatures" -ForegroundColor Gray

dotnet ef migrations add AddChatFeatures `
    --project glxt\glxt.csproj `
    --startup-project glxt\glxt.csproj `
    --context ApplicationDbContext `
    --output-dir Migrations `
    --verbose

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Migration created successfully!" -ForegroundColor Green
    
    # Show generated files
    if (Test-Path $migrationsPath) {
        Write-Host "`n  Generated migration files:" -ForegroundColor Cyan
        Get-ChildItem -Path $migrationsPath -Filter "*.cs" | ForEach-Object {
            Write-Host "    - $($_.Name)" -ForegroundColor Gray
        }
    }
    
    # Ask to apply migration
    Write-Host ""
    $applyMigration = Read-Host "  Apply to database now? (y/n)"
    if ($applyMigration -eq 'y' -or $applyMigration -eq 'Y') {
        Write-Host "`nApplying database migration..." -ForegroundColor Yellow
        dotnet ef database update `
            --project glxt\glxt.csproj `
            --startup-project glxt\glxt.csproj `
            --context ApplicationDbContext `
            --verbose
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Database updated successfully!" -ForegroundColor Green
        } else {
            Write-Host "  Database update failed" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  Migration creation failed" -ForegroundColor Red
    Write-Host "`nPossible causes:" -ForegroundColor Yellow
    Write-Host "  1. Invalid connection string in appsettings.json" -ForegroundColor Gray
    Write-Host "  2. ApplicationDbContext configuration issue" -ForegroundColor Gray
    Write-Host "  3. Model class compilation errors" -ForegroundColor Gray
}

Write-Host "`n=== Completed ===" -ForegroundColor Green