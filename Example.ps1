<#
.Synopsis
    Downloads and installs SHARP-MX-M904 printer from GitHub release.

.Description
    Downloads the latest release from GitHub, extracts it, and runs the installation script.
#>

param(
    [string]$PrinterName = "SHARP-MX-M904",
    [string]$IPAddress = "10.1.2.40"
)

# GitHub release URL
$ReleaseUrl = "https://github.com/LikeCarter/SHARP-MX-M904/archive/refs/tags/v1.0.1.zip"

# Create temp directory
$TempDir = Join-Path $env:TEMP "SHARP-MX-M904-$(Get-Random)"
$ZipFile = Join-Path $TempDir "release.zip"

Write-Host "Downloading SHARP-MX-M904 release..." -ForegroundColor Green

# Create directory and download
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Invoke-WebRequest -Uri $ReleaseUrl -OutFile $ZipFile -UseBasicParsing

# Extract and run
Write-Host "Extracting and installing..." -ForegroundColor Green
Expand-Archive -Path $ZipFile -DestinationPath $TempDir -Force

$ExtractedDir = Get-ChildItem -Path $TempDir -Directory | Where-Object { $_.Name -like "SHARP-MX-M904-*" } | Select-Object -First 1
$ScriptPath = Join-Path $ExtractedDir.FullName "Install-Printer.ps1"

# Run installation
& powershell.exe -ExecutionPolicy Bypass -File $ScriptPath -PrinterName $PrinterName -IPAddress $IPAddress

# Cleanup
Remove-Item -Path $TempDir -Recurse -Force

Write-Host "Installation completed!" -ForegroundColor Green
