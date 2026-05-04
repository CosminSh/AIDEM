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
New-Item -ItemType Directory -Path "$distFolder\app\models" -Force

# 2. Copy all files to the 'app' subfolder (keeping the mess hidden)
Write-Host "Organizing files..."
Copy-Item -Path "$releaseSource\*" -Destination "$distFolder\app" -Recurse

# Rename the exe for a better look
Rename-Item -Path "$distFolder\app\survival_aid_app.exe" -NewName "SurvivalAId.exe"

# 3. Create a README for your friends
$readmeContent = @"
SURVIVAL AID - OFFLINE EMERGENCY ASSISTANT
==========================================

QUICK START:
1. Run 'Survival AId.bat' to start the app.
2. The first time you run it, it will ask for the AI model.

AI MODEL SETUP:
- This app uses the Gemma-2b-IT model (~2GB).
- OPTION A: Follow the in-app download instructions (requires internet once).
- OPTION B: If you have the 'gemma-4-e2b-it.litertlm' file, place it in the 'app\models\' folder. The app will find it automatically!

SAFE & OFFLINE:
Everything stays on your device. No data ever leaves your computer.
"@
$readmeContent | Out-File -FilePath "$distFolder\README.txt" -Encoding utf8

# 4. Create a Launcher (Batch file) in the root
$launcherContent = @"
@echo off
echo Starting Survival AId...
start "" "%~dp0app\SurvivalAId.exe"
"@
$launcherContent | Out-File -FilePath "$distFolder\Survival AId.bat" -Encoding ascii

Write-Host "`nDone! Your organized app is in: $distFolder"
Write-Host "To share with friends:"
Write-Host "1. Zip the '$distFolder' folder."
Write-Host "2. Send the zip to them!"
