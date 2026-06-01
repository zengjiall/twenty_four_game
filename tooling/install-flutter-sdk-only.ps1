param(
  [string]$InstallRoot = "$env:USERPROFILE\develop"
)

$ErrorActionPreference = "Stop"

$downloadRoot = Join-Path $InstallRoot "_downloads"
$flutterRoot = Join-Path $InstallRoot "flutter"
$flutterBat = Join-Path $flutterRoot "bin\flutter.bat"

New-Item -ItemType Directory -Force -Path $downloadRoot | Out-Null

if (Test-Path -LiteralPath $flutterBat) {
  Write-Host "Flutter is already installed at $flutterRoot" -ForegroundColor Green
  exit 0
}

Write-Host "Resolving latest stable Flutter SDK for Windows..." -ForegroundColor Cyan
$manifest = Invoke-RestMethod "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
$stableHash = $manifest.current_release.stable
$stable = $manifest.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1

if (-not $stable) {
  throw "Could not resolve the latest stable Flutter release."
}

$flutterUrl = "$($manifest.base_url)/$($stable.archive)"
$flutterArchive = Join-Path $downloadRoot (Split-Path $stable.archive -Leaf)

if (Test-Path -LiteralPath $flutterArchive) {
  $existing = Get-Item -LiteralPath $flutterArchive
  if ($existing.Length -lt 100MB) {
    Remove-Item -LiteralPath $flutterArchive -Force
  }
}

if (-not (Test-Path -LiteralPath $flutterArchive)) {
  Write-Host "Downloading Flutter $($stable.version) with curl.exe..." -ForegroundColor Cyan
  curl.exe --fail --location --retry 5 --retry-delay 5 --output $flutterArchive $flutterUrl
}

$archive = Get-Item -LiteralPath $flutterArchive
if ($archive.Length -lt 100MB) {
  throw "Downloaded Flutter archive is unexpectedly small: $($archive.Length) bytes"
}

if (Test-Path -LiteralPath $flutterRoot) {
  Remove-Item -LiteralPath $flutterRoot -Recurse -Force
}

Write-Host "Extracting Flutter to $InstallRoot..." -ForegroundColor Cyan
Expand-Archive -LiteralPath $flutterArchive -DestinationPath $InstallRoot -Force

if (-not (Test-Path -LiteralPath $flutterBat)) {
  throw "Flutter extraction completed, but flutter.bat was not found at $flutterBat"
}

Write-Host "Flutter SDK installed at $flutterRoot" -ForegroundColor Green
