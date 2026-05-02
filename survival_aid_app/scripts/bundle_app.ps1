# Bundle Survival AId for distribution
# This script creates a clean "Release" folder ready to show friends.

$releaseSource = "build\windows\x64\runner\Release"
$distFolder = "dist\SurvivalAId"

if (-not (Test-Path $releaseSource)) {
    Write-Error "Release build not found. Run 'flutter build windows' first."
    exit
}

# 1. Clean up and create dist folder
if (Test-Path $distFolder) { Remove-Item -Recurse -Force $distFolder }
New-Item -ItemType Directory -Path "$distFolder\app" -Force

# 2. Copy all files to the 'app' subfolder (keeping the mess hidden)
Write-Host "Organizing files..."
Copy-Item -Path "$releaseSource\*" -Destination "$distFolder\app" -Recurse

# Rename the exe for a better look
Rename-Item -Path "$distFolder\app\survival_aid_app.exe" -NewName "SurvivalAId.exe"

# 3. Create a Launcher (Batch file) in the root
# Note: We'll call it "Survival AId.bat" but you can use a shortcut for a better icon
$launcherContent = @"
@echo off
start "" "%~dp0app\SurvivalAId.exe"
"@
$launcherContent | Out-File -FilePath "$distFolder\Survival AId.bat" -Encoding ascii

# 4. (Optional) Create a professional shortcut if on Windows
# This is tricky in pure PS without COM, so we'll skip for now but provide instructions.

Write-Host "`nDone! Your organized app is in: $distFolder"
Write-Host "To make it look perfect for your friends:"
Write-Host "1. Open the $distFolder folder."
Write-Host "2. Right-click 'app\survival_aid_app.exe' -> Send to -> Desktop (create shortcut)."
Write-Host "3. Move that shortcut into the $distFolder folder."
Write-Host "4. Rename it to 'Survival AId'."
Write-Host "5. Now you can zip the $distFolder folder and share it!"
