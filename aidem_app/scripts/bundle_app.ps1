# Master Release Script for AIDEM
# Consolidates Windows and Android builds into the root 'Releases' folder.

$projectRoot = "$PSScriptRoot\..\.."
$windowsSource = "build\windows\x64\runner\Release"
$androidSource = "android\app\build\outputs\apk\release\app-release.apk"
$windowsDist = "$projectRoot\Releases\Windows"
$androidDist = "$projectRoot\Releases\Android"

# --- 1. HANDLE WINDOWS ---
if (Test-Path $windowsSource) {
    Write-Host "--- Packaging Windows Release ---"
    if (Test-Path $windowsDist) { Remove-Item -Recurse -Force $windowsDist }
    New-Item -ItemType Directory -Path "$windowsDist\app" -Force
    New-Item -ItemType Directory -Path "$windowsDist\app\models" -Force

    Write-Host "Organizing Windows files..."
    Copy-Item -Path "$windowsSource\*" -Destination "$windowsDist\app" -Recurse
    Rename-Item -Path "$windowsDist\app\AIDEM.exe" -NewName "AIDEM.exe"

    $readmeContent = @"
AIDEM - OFFLINE EMERGENCY ASSISTANT
==========================================

QUICK START:
1. Run 'AIDEM.bat' to start the app.
2. The first time you run it, it will ask for the AI model.

AI MODEL SETUP:
- This app uses the Gemma-2b-IT model (~2GB).
- OPTION A: Follow the in-app download instructions (requires internet once).
- OPTION B: If you have the 'gemma-4-e2b-it.litertlm' file, place it in the 'app\models\' folder. The app will find it automatically!

SAFE & OFFLINE:
Everything stays on your device. No data ever leaves your computer.
"@
    $readmeContent | Out-File -FilePath "$windowsDist\README.txt" -Encoding utf8

    $launcherContent = @"
@echo off
echo Starting AIDEM...
start "" "%~dp0app\AIDEM.exe"
"@
    $launcherContent | Out-File -FilePath "$windowsDist\AIDEM.bat" -Encoding ascii
    Write-Host "Windows release ready in: Releases\Windows"
} else {
    Write-Warning "Windows build not found. Run 'flutter build windows' to include it."
}

# --- 2. HANDLE ANDROID ---
if (Test-Path $androidSource) {
    Write-Host "`n--- Packaging Android Release ---"
    if (-not (Test-Path $androidDist)) { New-Item -ItemType Directory -Path $androidDist -Force }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmm"
    $targetApk = "$androidDist\AIDEM_v1.0_$timestamp.apk"
    
    Copy-Item -Path $androidSource -Destination $targetApk -Force
    # Also keep a static name for the "Latest" version
    Copy-Item -Path $androidSource -Destination "$androidDist\AIDEM_Latest.apk" -Force
    
    Write-Host "Android APK ready in: Releases\Android"
} else {
    Write-Warning "Android build not found. Run 'flutter build apk' to include it."
}

Write-Host "`nDone! All your packages are now in the project root '\Releases' folder."
