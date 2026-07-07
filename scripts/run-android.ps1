# Run EduFrame on a connected Android phone (paths without spaces).
$ErrorActionPreference = "Stop"

$env:PUB_CACHE = "D:\pub-cache"
$flutter = "C:\flutter\bin\flutter.bat"
$projectRoot = Split-Path $PSScriptRoot -Parent

if (-not (Test-Path $flutter)) {
  Write-Error "Flutter not found at C:\flutter. Create the junction first (see scripts/README.md)."
}

function Get-AdbPath {
  $localProps = Join-Path $projectRoot "android\local.properties"
  if (Test-Path $localProps) {
    foreach ($line in Get-Content $localProps) {
      if ($line -match '^sdk\.dir=(.+)$') {
        $sdkDir = $matches[1].Trim() -replace '\\\\', '\'
        $adb = Join-Path $sdkDir "platform-tools\adb.exe"
        if (Test-Path $adb) { return $adb }
      }
    }
  }

  $defaultSdk = Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe"
  if (Test-Path $defaultSdk) { return $defaultSdk }

  return $null
}

function Show-NoDeviceHelp {
  Write-Host ""
  Write-Host "No Android phone or emulator detected." -ForegroundColor Red
  Write-Host ""
  Write-Host "EduFrame runs on Android/iOS only. Windows, Chrome, and Edge cannot run this app." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Connect your phone:" -ForegroundColor Cyan
  Write-Host "  1. Plug in the phone with a USB data cable (not charge-only)."
  Write-Host "  2. On the phone: Settings -> Developer options -> USB debugging ON."
  Write-Host "  3. Unlock the phone and tap Allow when asked to trust this PC."
  Write-Host "  4. Set USB mode to File transfer / MTP if prompted."
  Write-Host "  5. Run this script again."
  Write-Host ""
  Write-Host "Check connection:" -ForegroundColor Cyan
  Write-Host '  & "C:\Users\SHASHANK V A\AppData\Local\Android\sdk\platform-tools\adb.exe" devices'
  Write-Host ""
  Write-Host "You should see your phone listed as 'device' (not 'unauthorized' or empty)."
  Write-Host ""
}

Set-Location $projectRoot

& $flutter pub get

$adb = Get-AdbPath
if ($adb) {
  & $adb kill-server | Out-Null
  Start-Sleep -Milliseconds 500
  & $adb start-server | Out-Null
  $adbLines = & $adb devices
  $androidDevices = @(
    $adbLines |
      Select-Object -Skip 1 |
      Where-Object { $_.Trim() -and $_ -match '\tdevice$' }
  )

  if ($androidDevices.Count -eq 0) {
    Show-NoDeviceHelp
    exit 1
  }

  Write-Host "Android device(s) ready:" -ForegroundColor Green
  foreach ($line in $androidDevices) {
    Write-Host "  $line"
  }
  Write-Host ""
} else {
  Write-Host "Warning: adb not found. Continuing, but connect a phone before flutter run." -ForegroundColor Yellow
}

& $flutter run @args
