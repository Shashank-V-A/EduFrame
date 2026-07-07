# Run EduFrame on a connected Android phone (paths without spaces).
$ErrorActionPreference = "Stop"

$env:PUB_CACHE = "D:\pub-cache"
$flutter = "C:\flutter\bin\flutter.bat"

if (-not (Test-Path $flutter)) {
  Write-Error "Flutter not found at C:\flutter. Create the junction first (see README in scripts/)."
}

Set-Location (Split-Path $PSScriptRoot -Parent)

& $flutter pub get
& $flutter run @args
