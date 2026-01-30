# upload-world.ps1 - Upload a .mcworld file to VPS
# Usage: .\scripts\upload-world.ps1
#        .\scripts\upload-world.ps1 -WorldName home -FilePath "C:\path\to\world.mcworld"

param(
    [string]$WorldName,
    [string]$FilePath
)

$remoteHost = "root@72.60.176.152"
$remoteUploadsDir = "~/minecraft-server-manager/uploads"
$localUploadsDir = Join-Path (Get-Location) "uploads"

Write-Host ""
Write-Host "📦 Upload Minecraft World" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Ensure local uploads directory exists
if (-not (Test-Path $localUploadsDir)) {
    New-Item -ItemType Directory -Path $localUploadsDir | Out-Null
}

# Get world name if not provided
if (-not $WorldName) {
    $WorldName = Read-Host "Enter world name (e.g., home, creative)"
    if (-not $WorldName) {
        Write-Host "❌ World name cannot be empty" -ForegroundColor Red
        exit 1
    }
}

# Validate world name
if ($WorldName -notmatch "^[a-z0-9_-]+$") {
    Write-Host "❌ World name must be lowercase letters, numbers, hyphens, or underscores only" -ForegroundColor Red
    exit 1
}

# Find the .mcworld file
if (-not $FilePath) {
    # First check in uploads folder
    $uploadsFile = Join-Path $localUploadsDir "$WorldName.mcworld"

    if (Test-Path $uploadsFile) {
        $FilePath = $uploadsFile
        Write-Host "Found: $FilePath" -ForegroundColor Green
    } else {
        Write-Host "No file found at: $uploadsFile" -ForegroundColor Yellow
        Write-Host ""
        $FilePath = Read-Host "Enter full path to .mcworld file"

        if (-not $FilePath) {
            Write-Host "❌ File path cannot be empty" -ForegroundColor Red
            exit 1
        }
    }
}

# Check if file exists
if (-not (Test-Path $FilePath)) {
    Write-Host "❌ File not found: $FilePath" -ForegroundColor Red
    exit 1
}

# Verify it's a .mcworld file
if (-not $FilePath.EndsWith(".mcworld")) {
    Write-Host "⚠️ Warning: File does not have .mcworld extension" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? [y/N]"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 0
    }
}

# Get file size
$fileSize = (Get-Item $FilePath).Length
$fileSizeMB = [math]::Round($fileSize / 1MB, 2)
Write-Host ""
Write-Host "File size: $fileSizeMB MB" -ForegroundColor Gray

# Ensure remote uploads directory exists
Write-Host ""
Write-Host "📁 Ensuring remote directory exists..." -ForegroundColor Cyan
ssh $remoteHost "mkdir -p $remoteUploadsDir"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create remote directory" -ForegroundColor Red
    exit 1
}

# Upload the file
$remotePath = "$remoteUploadsDir/$WorldName.mcworld"
Write-Host "📤 Uploading to VPS..." -ForegroundColor Cyan
Write-Host "   $FilePath -> $remotePath" -ForegroundColor Gray
Write-Host ""

scp "$FilePath" "${remoteHost}:${remotePath}"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Upload failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Upload complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps (on VPS via SSH):" -ForegroundColor Yellow
Write-Host "  cd ~/minecraft-server-manager" -ForegroundColor Gray
Write-Host "  ./scripts/extract-world.sh $WorldName" -ForegroundColor Gray
Write-Host ""
