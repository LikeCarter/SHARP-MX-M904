<#
.Synopsis
    Installs a printer driver and printer via Microsoft Intune.
    Required files should be in the same directory as the script when creating a Win32 app for deployment via Intune.

.Description
    This script is designed for silent installation of printer drivers and printers,
    especially useful in environments like Microsoft Intune. It checks for existing
    components (printer port, driver, printer) before attempting to create them,
    ensuring idempotency. Error handling is implemented for each major step to
    provide robust and reliable deployment.

.Notes
    Created on:    16/07/2025
    Updated on:    02/10/2025
    Created by:    @LikeCarter
    Filename:      Install-Printer.ps1

    ### Powershell Commands for Intune ###

    Install Command:
    powershell.exe -ExecutionPolicy Bypass -File .\Install-Printer.ps1 -PrinterName "SHARP-MX-M904" -IPAddress "10.1.2.40"

    Remove Command (if a separate removal script is used):
    powershell.exe -ExecutionPolicy Bypass -File .\Remove-Printer.ps1

    Detection Rule Example (for Intune Win32 App):
    Rule Type:          Registry
    Key path:           HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\[PrinterName]
    Value:              Name
    Detection method:   String comparison
    Operator:           Equals
    Value:              [PrinterName]
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$PrinterName,
    
    [Parameter(Mandatory=$true)]
    [string]$IPAddress
)

# Get the script directory
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Define printer driver name
$drivername = "SHARP UD3 PCL6"

# Generate port name automatically using Windows convention
$PortName = "IP_" + $IPAddress

# Stage Drivers
Write-Host "Staging printer drivers..." -ForegroundColor Green
try {
    $stageResult = pnputil.exe /add-driver "$psscriptroot\sv0emenu.inf" /install
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Driver staging failed with exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    Write-Host "Driver staging completed successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to stage drivers: $($_.Exception.Message)"
    exit 1
}

# Install Printer Driver
Write-Host "Installing printer driver..." -ForegroundColor Green
try {
    Add-PrinterDriver -Name $drivername -ErrorAction Stop
    Write-Host "Printer driver installed successfully" -ForegroundColor Green
} catch {
    Write-Warning "Printer driver may already be installed or installation failed: $($_.Exception.Message)"
}

# Install Printer Port | Check if the port already exists
Write-Host "Checking for existing printer port..." -ForegroundColor Green
$checkPortExists = Get-Printerport -Name $PortName -ErrorAction SilentlyContinue

if (-not $checkPortExists) {
    Write-Host "Creating printer port: $PortName" -ForegroundColor Yellow
    try {
        Add-PrinterPort -name $PortName -PrinterHostAddress $IPAddress -ErrorAction Stop
        Write-Host "Printer port created successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to create printer port: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "Printer port already exists: $PortName" -ForegroundColor Cyan
}

# Check if Printer Driver Exists
Write-Host "Verifying printer driver installation..." -ForegroundColor Green
$printDriverExists = Get-PrinterDriver -name $DriverName -ErrorAction SilentlyContinue

# Install Printer
if ($printDriverExists) {
    Write-Host "Installing printer: $PrinterName" -ForegroundColor Green
    try {
        Add-Printer -Name $PrinterName -PortName $PortName -DriverName $DriverName -ErrorAction Stop
        Write-Host "Printer installation completed successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to install printer: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Error "Printer Driver not installed - installation failed"
    exit 1
}

# Wait for system to stabilize
Write-Host "Waiting for system to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 60
