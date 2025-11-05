# Setup Android SDK cmdline-tools and accept licenses
# Usage:
# 1) Download commandlinetools-win-*.zip from:
#    https://developer.android.com/studio#command-line-tools-only
# 2) Save it to your Downloads folder
# 3) Open PowerShell and run:
#    powershell -ExecutionPolicy Bypass -File .\scripts\setup-android.ps1

$ErrorActionPreference = 'Stop'

# Resolve SDK root
$sdk = $env:ANDROID_SDK_ROOT
if (-not $sdk) { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
if (-not (Test-Path $sdk)) {
  Write-Error "Android SDK folder not found at '$sdk'. Create it or install Android Studio first."
}

Write-Host "SDK root: $sdk"

# Ensure cmdline-tools target folder exists
$cmdLatest = Join-Path $sdk 'cmdline-tools\latest'
$cmdParent = Split-Path $cmdLatest -Parent
New-Item -ItemType Directory -Force -Path $cmdParent | Out-Null

# Find the downloaded zip
$zip = Get-ChildItem -Path "$env:USERPROFILE\Downloads" -Filter 'commandlinetools-win*.zip' -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $zip) {
  Write-Host "Could not find 'commandlinetools-win*.zip' in Downloads. Please download it first." -ForegroundColor Yellow
  Write-Host "Download: https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip (example)"
  exit 2
}

Write-Host "Using zip: $($zip.FullName)"

# Extract to a temp
$tmp = Join-Path $env:TEMP ("cmdline-tools-" + (Get-Random))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
Expand-Archive -Path $zip.FullName -DestinationPath $tmp -Force

# The zip contains a 'cmdline-tools' folder; move its contents to 'latest'
$extracted = Join-Path $tmp 'cmdline-tools'
if (-not (Test-Path $extracted)) { Write-Error "Unexpected zip contents. 'cmdline-tools' folder not found." }

# Clean previous 'latest'
if (Test-Path $cmdLatest) { Remove-Item -Recurse -Force $cmdLatest }
New-Item -ItemType Directory -Force -Path $cmdLatest | Out-Null

# Move items into latest
Get-ChildItem -Path $extracted | ForEach-Object { Move-Item -Force $_.FullName -Destination $cmdLatest }

# Verify sdkmanager
$sdkManager = Join-Path $cmdLatest 'bin\sdkmanager.bat'
if (-not (Test-Path $sdkManager)) { Write-Error "sdkmanager not found at $sdkManager" }

# Install essential components
& $sdkManager --sdk_root="$sdk" --install "platform-tools" "platforms;android-35" "build-tools;35.0.0" "cmdline-tools;latest"

# Accept licenses
& $sdkManager --sdk_root="$sdk" --licenses

Write-Host "Android cmdline-tools installed and licenses accepted. Run 'flutter doctor' again." -ForegroundColor Green
