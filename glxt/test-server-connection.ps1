# Server Connection Test Script
# Usage: .\test-server-connection.ps1

param(
    [string]$ServerIP = "",
    [int]$ServerPort = 22
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   Server Connection Test" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

if ([string]::IsNullOrWhiteSpace($ServerIP)) {
    $ServerIP = Read-Host "Please enter server IP address"
}

if ($ServerPort -eq 0) {
    $portInput = Read-Host "Please enter SSH port (default: 22)"
    if (-not [string]::IsNullOrWhiteSpace($portInput)) {
        $ServerPort = [int]$portInput
    } else {
        $ServerPort = 22
    }
}

Write-Host "Testing connection to: $ServerIP`:$ServerPort" -ForegroundColor Yellow
Write-Host ""

# Test 1: Ping
Write-Host "[1/4] Testing ICMP (Ping)..." -ForegroundColor Yellow
try {
    $pingResult = Test-Connection -ComputerName $ServerIP -Count 2 -Quiet
    if ($pingResult) {
        Write-Host "  PASS - Server is reachable" -ForegroundColor Green
    } else {
        Write-Host "  FAIL - Server is not responding to ping" -ForegroundColor Red
        Write-Host "  Note: Some servers disable ICMP, this is not critical" -ForegroundColor Gray
    }
} catch {
    Write-Host "  FAIL - Unable to ping server" -ForegroundColor Red
}

# Test 2: TCP Port
Write-Host ""
Write-Host "[2/4] Testing TCP port $ServerPort..." -ForegroundColor Yellow
try {
    $portTest = Test-NetConnection -ComputerName $ServerIP -Port $ServerPort -WarningAction SilentlyContinue
    if ($portTest.TcpTestSucceeded) {
        Write-Host "  PASS - Port $ServerPort is open" -ForegroundColor Green
    } else {
        Write-Host "  FAIL - Port $ServerPort is not accessible" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Possible reasons:" -ForegroundColor Yellow
        Write-Host "    1. Firewall blocking the port" -ForegroundColor White
        Write-Host "    2. SSH service not running" -ForegroundColor White
        Write-Host "    3. Wrong port number" -ForegroundColor White
        Write-Host "    4. Security group not configured (cloud servers)" -ForegroundColor White
    }
} catch {
    Write-Host "  FAIL - Cannot test port" -ForegroundColor Red
}

# Test 3: SSH Connection
Write-Host ""
Write-Host "[3/4] Testing SSH connection..." -ForegroundColor Yellow
Write-Host "  Attempting SSH connection (you may need to enter password)..." -ForegroundColor Gray

$sshTest = "echo 'SSH connection successful'"
try {
    $result = ssh -p $ServerPort -o ConnectTimeout=10 -o BatchMode=yes root@$ServerIP $sshTest 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  PASS - SSH connection successful" -ForegroundColor Green
    } else {
        Write-Host "  FAIL - SSH connection failed" -ForegroundColor Red
        Write-Host "  Error: $result" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Possible solutions:" -ForegroundColor Yellow
        Write-Host "    1. Configure SSH key authentication" -ForegroundColor White
        Write-Host "    2. Try manual connection: ssh -p $ServerPort root@$ServerIP" -ForegroundColor White
        Write-Host "    3. Use cloud provider's web console instead" -ForegroundColor White
    }
} catch {
    Write-Host "  FAIL - Cannot execute SSH" -ForegroundColor Red
    Write-Host "  Make sure OpenSSH client is installed" -ForegroundColor Gray
}

# Test 4: DNS Resolution
Write-Host ""
Write-Host "[4/4] Testing DNS resolution..." -ForegroundColor Yellow
try {
    $dnsTest = [System.Net.Dns]::GetHostEntry($ServerIP)
    Write-Host "  PASS - DNS resolution successful" -ForegroundColor Green
    Write-Host "  Hostname: $($dnsTest.HostName)" -ForegroundColor Gray
} catch {
    Write-Host "  INFO - No reverse DNS (this is normal for IP addresses)" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   Test Summary" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Server Information:" -ForegroundColor Yellow
Write-Host "  IP Address: $ServerIP" -ForegroundColor White
Write-Host "  SSH Port:   $ServerPort" -ForegroundColor White
Write-Host ""

if ($portTest.TcpTestSucceeded) {
    Write-Host "Connection Status: GOOD" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can proceed with deployment:" -ForegroundColor Yellow
    Write-Host "  .\glxt\upload-to-server-port.ps1 -ServerIP `"$ServerIP`" -ServerPort $ServerPort" -ForegroundColor White
} else {
    Write-Host "Connection Status: FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Recommended solutions:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Check cloud provider settings:" -ForegroundColor Cyan
    Write-Host "   - Security Group: Allow inbound port $ServerPort" -ForegroundColor White
    Write-Host "   - Firewall: Allow SSH connections" -ForegroundColor White
    Write-Host "   - Verify you're using the PUBLIC IP address" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Use cloud provider's web console:" -ForegroundColor Cyan
    Write-Host "   - Alibaba Cloud: ECS -> Remote Connection -> VNC" -ForegroundColor White
    Write-Host "   - Tencent Cloud: CVM -> Login -> Standard Login" -ForegroundColor White
    Write-Host "   - AWS: EC2 -> Connect -> EC2 Instance Connect" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Use Git deployment (recommended):" -ForegroundColor Cyan
    Write-Host "   See: .\glxt\GIT_DEPLOY_GUIDE.md" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Manual file upload:" -ForegroundColor Cyan
    Write-Host "   - Use WinSCP or FileZilla" -ForegroundColor White
    Write-Host "   - Or use cloud provider's file upload feature" -ForegroundColor White
}

Write-Host ""
Read-Host "Press any key to exit"
