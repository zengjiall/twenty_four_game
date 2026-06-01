param(
  [string]$FlutterRoot = "$env:USERPROFILE\develop\flutter"
)

$ErrorActionPreference = "Stop"

$flutterBat = Join-Path $FlutterRoot "bin\flutter.bat"
if (-not (Test-Path -LiteralPath $flutterBat)) {
  Write-Error @"
Flutter SDK was not found at:
  $FlutterRoot

Install or extract Flutter there, or pass another path:
  .\tooling\use-flutter.ps1 -FlutterRoot C:\path\to\flutter
"@
}

$flutterBin = Join-Path $FlutterRoot "bin"
if (($env:Path -split ";") -notcontains $flutterBin) {
  $env:Path = "$flutterBin;$env:Path"
}

Write-Host "Flutter added for this PowerShell session:" -ForegroundColor Green
Write-Host "  $flutterBin"
flutter --version
dart --version
