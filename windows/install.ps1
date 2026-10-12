<#
.SYNOPSIS
  Installs QUERVEX 1.0.0 for the current Windows user (no administrator rights needed).
.DESCRIPTION
  Downloads the standalone executable of release v1.0.0 (or uses it if it sits next to this
  script), checks its SHA-256 fingerprint, copies it to %LOCALAPPDATA%\Programs\quervex and adds
  that folder to your user PATH. Without a standalone executable for your machine, falls back to
  npm (Node.js >= 22).

  One-line install from PowerShell:
    irm https://github.com/fthcodexa-be/quervex-cli/releases/download/v1.0.0/install.ps1 | iex
.PARAMETER Mode
  auto (default): standalone executable, otherwise npm.   exe: executable only.   npm: npm only.
.PARAMETER InstallDir
  Target folder for the executable (default: %LOCALAPPDATA%\Programs\quervex).
.PARAMETER NoPath
  Do not modify the user PATH.
#>
[CmdletBinding()]
param(
  [ValidateSet('auto', 'exe', 'npm')][string]$Mode = 'auto',
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\quervex'),
  [switch]$NoPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # PowerShell 5.1: the progress bar slows downloads down
$Version = '1.0.0'
$BaseUrl = if ($env:QUERVEX_DOWNLOAD_BASE) { $env:QUERVEX_DOWNLOAD_BASE.TrimEnd('/') } else { 'https://github.com/fthcodexa-be/quervex-cli/releases/download/v1.0.0' }
# SHA-256 of the release executables, written by the build: a download is never run unchecked.
$Sha256 = @{
  'quervex-setup-windows-x64.exe'   = 'c184c166b8d90f2734c4a36d91773f46e17744880e28cb64aecaa0fff058c997'
  'quervex-setup-windows-arm64.exe' = ''
}
# Empty when run through "irm | iex": nothing can sit next to the script.
$Here = $PSScriptRoot

function Say([string]$msg) { Write-Host "  > $msg" -ForegroundColor Cyan }
function Ok([string]$msg) { Write-Host "  + $msg" -ForegroundColor Green }
# throw rather than exit: "irm | iex" must never close the user's PowerShell window.
function Die([string]$msg) { Write-Host "  x $msg" -ForegroundColor Red; throw "QUERVEX installation failed: $msg" }

function Get-NodeMajor {
  try {
    $v = & node --version 2>$null
    if ($v -match '^v(\d+)') { return [int]$Matches[1] }
  } catch {}
  return 0
}

# Notifies Windows (WM_SETTINGCHANGE) so that newly opened terminals see the new PATH.
function Publish-EnvChange {
  [Environment]::SetEnvironmentVariable('QUERVEX_INSTALL_TMP', '1', 'User')
  [Environment]::SetEnvironmentVariable('QUERVEX_INSTALL_TMP', $null, 'User')
}

function Add-UserPath([string]$dir) {
  $key = Get-Item -Path 'HKCU:\Environment'
  # Raw value: keeps entries such as %USERPROFILE%\... unexpanded.
  $current = $key.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
  $parts = @($current -split ';' | Where-Object { $_ -ne '' })
  if ($parts -contains $dir) { Ok "Already in PATH: $dir"; return }
  New-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value (($parts + $dir) -join ';') -PropertyType ExpandString -Force | Out-Null
  Publish-EnvChange
  Ok "Added to your user PATH: $dir"
}

# Local copy next to the script, otherwise download; in both cases the fingerprint must match.
function Get-Executable([string]$asset, [string]$expected) {
  if ($Here) {
    $local = Join-Path $Here $asset
    if (Test-Path $local) {
      Say "Using $local"
      $file = $local
    }
  }
  if (-not $file) {
    $file = Join-Path ([IO.Path]::GetTempPath()) "$asset.$PID.download"
    Say "Downloading $BaseUrl/$asset"
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    try { Invoke-WebRequest -Uri "$BaseUrl/$asset" -OutFile $file -UseBasicParsing }
    catch { Remove-Item $file -Force -ErrorAction SilentlyContinue; Die "Download failed: $($_.Exception.Message)" }
  }
  $actual = (Get-FileHash -Path $file -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actual -ne $expected) {
    if ($file -like '*.download') { Remove-Item $file -Force -ErrorAction SilentlyContinue }
    Die "SHA-256 mismatch for $asset (expected $expected, got $actual): file rejected."
  }
  Ok 'SHA-256 fingerprint verified'
  return $file
}

Write-Host ''
Write-Host "  QUERVEX $Version - installer" -ForegroundColor Magenta
Write-Host ''

$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
$asset = "quervex-setup-windows-$arch.exe"
$expected = $Sha256[$asset]
# Windows on ARM runs x64 programs: fall back to the x64 executable when there is no arm64 one.
if (-not $expected -and $arch -eq 'arm64') { $asset = 'quervex-setup-windows-x64.exe'; $expected = $Sha256[$asset] }

if ($Mode -eq 'auto') {
  if ($expected) { $Mode = 'exe' }
  elseif ((Get-NodeMajor) -ge 22) { $Mode = 'npm' }
  else { Die "No standalone executable for windows-$arch and Node.js >= 22 was not found. Install Node.js (https://nodejs.org) and run this script again." }
}

if ($Mode -eq 'exe') {
  if (-not $expected) { Die "No standalone executable for windows-$arch in this release." }
  $source = Get-Executable $asset $expected
  Say "Installing to $InstallDir"
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  $target = Join-Path $InstallDir 'quervex.exe'
  try { Copy-Item -Path $source -Destination $target -Force }
  catch { Die "Cannot write $target (is QUERVEX running? close it and try again): $($_.Exception.Message)" }
  finally { if ($source -like '*.download') { Remove-Item $source -Force -ErrorAction SilentlyContinue } }
  Unblock-File -Path $target -ErrorAction SilentlyContinue
  Ok "Copied to $target"
  if (-not $NoPath) { Add-UserPath $InstallDir } else { Say 'PATH left unchanged (-NoPath).' }
  $check = & $target --version
}
else {
  if ((Get-NodeMajor) -lt 22) { Die 'Node.js >= 22 is required for the npm install.' }
  Say "npm install -g quervex@$Version"
  & npm install -g "quervex@$Version"
  if ($LASTEXITCODE -ne 0) { Die 'npm install failed.' }
  $check = & quervex --version
}

if ($check -ne $Version) { Die "The installed program does not start correctly (got: $check)." }
Write-Host ''
Ok "QUERVEX $check installed."
Write-Host '  Open a NEW terminal and type: quervex' -ForegroundColor Cyan
Write-Host '  (restart VS Code if you use its integrated terminal)' -ForegroundColor DarkGray
Write-Host ''
