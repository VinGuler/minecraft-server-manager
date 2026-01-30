# download-backups.ps1 - Download backups from VPS
# Usage: .\scripts\download-backups.ps1
#        .\scripts\download-backups.ps1 -WorldName home
#        .\scripts\download-backups.ps1 -All

param(
    [string]$WorldName,
    [switch]$All
)

$remoteHost = "root@72.60.176.152"
$remoteBackupDir = "~/backups"
$localBackupDir = Join-Path (Get-Location) "backups"

Write-Host ""
Write-Host "💾 Download Minecraft Backups" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Ensure local backups directory exists
if (-not (Test-Path $localBackupDir)) {
    New-Item -ItemType Directory -Path $localBackupDir | Out-Null
}

# Function to download a single world's backups
function Download-WorldBackup {
    param([string]$World)

    $remotePath = "$remoteBackupDir/$World"
    $localPath = Join-Path $localBackupDir $World
    $tempPath = Join-Path $localBackupDir "${World}_temp"

    Write-Host ""
    Write-Host "📥 Downloading backups for '$World'..." -ForegroundColor Cyan

    # Remove temp folder if it exists
    if (Test-Path $tempPath) {
        Remove-Item -Recurse -Force $tempPath
    }

    # Download
    scp -r "${remoteHost}:${remotePath}" $tempPath

    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️ Failed to download backups for '$World' (may not exist)" -ForegroundColor Yellow
        return $false
    }

    # Remove old local backups for this world
    if (Test-Path $localPath) {
        Remove-Item -Recurse -Force $localPath
    }

    # Rename temp to final
    Rename-Item $tempPath $localPath

    # Count backups
    $backupCount = (Get-ChildItem $localPath -Filter "*.zip" | Measure-Object).Count
    Write-Host "✅ Downloaded $backupCount backup(s) for '$World'" -ForegroundColor Green

    return $true
}

# Determine what to download
if ($All) {
    # Download all worlds
    Write-Host "Fetching list of worlds with backups..." -ForegroundColor Gray

    $worldList = ssh $remoteHost "ls -1 $remoteBackupDir 2>/dev/null"

    if ($LASTEXITCODE -ne 0 -or -not $worldList) {
        Write-Host "⚠️ No backups found on remote server" -ForegroundColor Yellow
        exit 0
    }

    $worlds = $worldList -split "`n" | Where-Object { $_ -ne "" }

    Write-Host "Found worlds: $($worlds -join ', ')" -ForegroundColor Gray

    $successCount = 0
    $failCount = 0

    foreach ($world in $worlds) {
        $world = $world.Trim()
        if ($world) {
            if (Download-WorldBackup -World $world) {
                $successCount++
            } else {
                $failCount++
            }
        }
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "✅ Download complete!" -ForegroundColor Green
    Write-Host "   Successful: $successCount" -ForegroundColor Gray
    if ($failCount -gt 0) {
        Write-Host "   Failed: $failCount" -ForegroundColor Red
    }

} elseif ($WorldName) {
    # Download specific world
    Download-WorldBackup -World $WorldName

} else {
    # Ask user
    Write-Host "Download options:" -ForegroundColor Yellow
    Write-Host "  1. All worlds" -ForegroundColor Gray
    Write-Host "  2. Specific world" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Enter choice [1/2]"

    if ($choice -eq "1") {
        # Recursive call with -All
        & $PSCommandPath -All
    } else {
        $WorldName = Read-Host "Enter world name"
        if ($WorldName) {
            Download-WorldBackup -World $WorldName
        } else {
            Write-Host "❌ World name cannot be empty" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""
Write-Host "Backups stored in: $localBackupDir" -ForegroundColor Gray
Write-Host ""
