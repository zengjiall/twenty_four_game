param(
  [string]$InstallRoot = "$env:USERPROFILE\develop"
)

$ErrorActionPreference = "Stop"

function Add-SessionPath {
  param([string]$PathToAdd)
  if (($env:Path -split ";") -notcontains $PathToAdd) {
    $env:Path = "$PathToAdd;$env:Path"
  }
}

function Add-UserPath {
  param([string]$PathToAdd)
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $parts = @()
  if ($userPath) {
    $parts = $userPath -split ";"
  }
  if ($parts -notcontains $PathToAdd) {
    $newPath = if ($userPath) { "$PathToAdd;$userPath" } else { $PathToAdd }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
  }
}

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
$downloadRoot = Join-Path $InstallRoot "_downloads"
New-Item -ItemType Directory -Force -Path $downloadRoot | Out-Null

$gitRoot = Join-Path $InstallRoot "PortableGit"
$gitExe = Join-Path $gitRoot "cmd\git.exe"

if (-not (Test-Path -LiteralPath $gitExe)) {
  Write-Host "Finding latest Portable Git for Windows..." -ForegroundColor Cyan
  $release = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest"
  $asset = $release.assets |
    Where-Object { $_.name -match "^PortableGit-.*-64-bit\.7z\.exe$" } |
    Select-Object -First 1

  if (-not $asset) {
    throw "Could not find a PortableGit 64-bit asset in the latest release."
  }

  $gitArchive = Join-Path $downloadRoot $asset.name
  Write-Host "Downloading $($asset.name)..." -ForegroundColor Cyan
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $gitArchive

  if (Test-Path -LiteralPath $gitRoot) {
    Remove-Item -LiteralPath $gitRoot -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $gitRoot | Out-Null

  Write-Host "Extracting Portable Git..." -ForegroundColor Cyan
  Start-Process -FilePath $gitArchive -ArgumentList "-o$gitRoot", "-y" -Wait -NoNewWindow
}

$flutterRoot = Join-Path $InstallRoot "flutter"
$flutterBat = Join-Path $flutterRoot "bin\flutter.bat"

if (-not (Test-Path -LiteralPath $flutterBat)) {
  Write-Host "Finding latest stable Flutter SDK for Windows..." -ForegroundColor Cyan
  $manifest = Invoke-RestMethod "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
  $stableHash = $manifest.current_release.stable
  $stable = $manifest.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1

  if (-not $stable) {
    throw "Could not resolve the latest stable Flutter release."
  }

  $flutterUrl = "$($manifest.base_url)/$($stable.archive)"
  $flutterArchive = Join-Path $downloadRoot (Split-Path $stable.archive -Leaf)

  if (Test-Path -LiteralPath $flutterArchive) {
    $existingArchive = Get-Item -LiteralPath $flutterArchive
    if ($existingArchive.Length -lt 100MB) {
      Remove-Item -LiteralPath $flutterArchive -Force
    }
  }

  Write-Host "Downloading Flutter $($stable.version) with curl.exe..." -ForegroundColor Cyan
  curl.exe --fail --location --retry 5 --retry-delay 5 --output $flutterArchive $flutterUrl

  $downloadedArchive = Get-Item -LiteralPath $flutterArchive
  if ($downloadedArchive.Length -lt 100MB) {
    throw "Downloaded Flutter archive is unexpectedly small: $($downloadedArchive.Length) bytes"
  }

  if (Test-Path -LiteralPath $flutterRoot) {
    Remove-Item -LiteralPath $flutterRoot -Recurse -Force
  }

  Write-Host "Extracting Flutter..." -ForegroundColor Cyan
  Expand-Archive -LiteralPath $flutterArchive -DestinationPath $InstallRoot -Force
}

$gitCmd = Join-Path $gitRoot "cmd"
$flutterBin = Join-Path $flutterRoot "bin"

Add-SessionPath $gitCmd
Add-SessionPath $flutterBin
Add-UserPath $gitCmd
Add-UserPath $flutterBin

Write-Host ""
Write-Host "Installed tool paths:" -ForegroundColor Green
Write-Host "  Git:     $gitCmd"
Write-Host "  Flutter: $flutterBin"
Write-Host ""

git --version
flutter --version
dart --version
flutter doctor
