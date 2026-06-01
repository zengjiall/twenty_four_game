param(
  [string]$FlutterRoot = "$env:USERPROFILE\develop\flutter",
  [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$flutterBin = Join-Path $FlutterRoot "bin"
$flutterBat = Join-Path $flutterBin "flutter.bat"

if (-not (Test-Path -LiteralPath $flutterBat)) {
  Write-Error @"
Flutter SDK was not found at:
  $FlutterRoot

Install or extract Flutter there, or pass another path:
  .\tooling\run-lan-web.ps1 -FlutterRoot C:\path\to\flutter
"@
}

if (($env:Path -split ";") -notcontains $flutterBin) {
  $env:Path = "$flutterBin;$env:Path"
}

$ipConfig = ipconfig | Select-String -Pattern "IPv4 Address"
$lanIp = ($ipConfig | ForEach-Object {
  ($_ -split ":")[-1].Trim()
} | Where-Object {
  $_ -match "^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\."
} | Select-Object -First 1)

if ($lanIp) {
  Write-Host "Phone URL on the same Wi-Fi:" -ForegroundColor Green
  Write-Host "  http://$lanIp`:$Port/"
  Write-Host ""
}

Set-Location -LiteralPath $projectRoot
flutter run -d web-server --web-hostname 0.0.0.0 --web-port $Port
