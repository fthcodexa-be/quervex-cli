<#
.SYNOPSIS
  Uninstalls QUERVEX for the current Windows user.
.PARAMETER InstallDir
  Folder used at install time (default: %LOCALAPPDATA%\Programs\quervex).
.PARAMETER Purge
  Also deletes the configuration folder ~\.quervex (history, profiles, .env).
#>
[CmdletBinding()]
param(
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\quervex'),
  [switch]$Purge
)

$ErrorActionPreference = 'Stop'
function Ok([string]$msg) { Write-Host "  + $msg" -ForegroundColor Green }
function Say([string]$msg) { Write-Host "  > $msg" -ForegroundColor Cyan }

Write-Host ''
Write-Host '  QUERVEX - uninstaller' -ForegroundColor Magenta
Write-Host ''

if (Test-Path $InstallDir) {
  Remove-Item -Path $InstallDir -Recurse -Force
  Ok "Removed $InstallDir"
}

$key = Get-Item -Path 'HKCU:\Environment'
$current = $key.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
$parts = @($current -split ';' | Where-Object { $_ -ne '' })
if ($parts -contains $InstallDir) {
  $kept = @($parts | Where-Object { $_ -ne $InstallDir })
  New-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value ($kept -join ';') -PropertyType ExpandString -Force | Out-Null
  [Environment]::SetEnvironmentVariable('QUERVEX_INSTALL_TMP', '1', 'User')
  [Environment]::SetEnvironmentVariable('QUERVEX_INSTALL_TMP', $null, 'User')
  Ok 'Removed from your user PATH'
}

if (Get-Command npm -ErrorAction SilentlyContinue) {
  $global = & npm ls -g --depth=0 quervex 2>$null
  if ($global -match 'quervex@') {
    Say 'npm uninstall -g quervex'
    & npm uninstall -g quervex | Out-Null
    Ok 'npm package removed'
  }
}

if ($Purge) {
  $config = Join-Path $HOME '.quervex'
  if (Test-Path $config) { Remove-Item -Path $config -Recurse -Force; Ok "Removed $config" }
}

Write-Host ''
Ok 'QUERVEX uninstalled.'
Write-Host ''
