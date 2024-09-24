# maintenance.ps1
# Windows Maintenance Script

# Check for administrator privileges
If (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Please run as administrator."
    Pause
    Exit
}

# Set up logging
$LogDirectory = "$env:SystemDrive\MaintenanceLogs"
If (!(Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}
$LogFile = "$LogDirectory\MaintenanceLog_{0}.log" -f (Get-Date -Format "yyyyMMdd")

# Function to write logs with log levels
Function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry
}

# Archive old logs
Function Archive-OldLogs {
    param(
        [int]$DaysToKeep = 30
    )
    Get-ChildItem -Path $LogDirectory -Filter "MaintenanceLog_*.log" | Where-Object {
        ($_.LastWriteTime -lt (Get-Date).AddDays(-$DaysToKeep))
    } | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Call Archive-OldLogs
Archive-OldLogs -DaysToKeep 30

# Start of script
Write-Log "Maintenance script started."

# Environment Checks
Write-Log "Performing environment checks."

# Check free disk space on C: drive
$FreeSpace = (Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace
$FreeSpaceGB = [math]::Round($FreeSpace / 1GB, 2)
if ($FreeSpaceGB -lt 10) {
    Write-Log "Less than 10 GB free on C: drive. ($FreeSpaceGB GB available)" "WARNING"
}

# Check battery status (for laptops)
$BatteryStatus = Get-WmiObject -Class Win32_Battery -ErrorAction SilentlyContinue
if ($BatteryStatus) {
    if ($BatteryStatus.BatteryStatus -ne 2) {
        Write-Log "Battery is not fully charged or device is not plugged in." "WARNING"
    }
}

# Function to prompt user
Function Prompt-User {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    do {
        $response = Read-Host "$Message (y/n)"
    } while ($response -ne 'y' -and $response -ne 'n')
    return $response
}

# Function to execute commands with error handling and retries
Function Execute-Command {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,
        [string]$TaskName,
        [int]$MaxRetries = 1,
        [int]$RetryInterval = 5
    )
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            $Output = & $Command
            Write-Log "$TaskName output:`n$Output" "INFO"
            Write-Log "$TaskName completed successfully."
            break
        } catch {
            Write-Log "$TaskName attempt $attempt failed: $_" "ERROR"
            if ($attempt -lt $MaxRetries) {
                Write-Log "Retrying in $RetryInterval seconds..."
                Start-Sleep -Seconds $RetryInterval
            } else {
                Write-Log "$TaskName failed after $MaxRetries attempts." "ERROR"
            }
        }
    }
}

# Task 1: CHKDSK
$RunCHKDSK = Prompt-User "Do you want to run CHKDSK to check disk for errors?"
if ($RunCHKDSK -eq 'y') {
    Write-Log "Checking disk with CHKDSK..."
    Execute-Command -Command { chkdsk C: /F } -TaskName "CHKDSK"
} else {
    Write-Log "Skipping CHKDSK."
}

# Task 2: DISM
$RunDISM = Prompt-User "Do you want to repair system files with DISM?"
if ($RunDISM -eq 'y') {
    Write-Log "Repairing system files with DISM..."
    Execute-Command -Command { DISM.exe /Online /Cleanup-Image /RestoreHealth } -TaskName "DISM"
} else {
    Write-Log "Skipping DISM."
}

# Task 3: SFC
$RunSFC = Prompt-User "Do you want to run System File Checker (SFC)?"
if ($RunSFC -eq 'y') {
    Write-Log "Repairing system files with SFC..."
    Execute-Command -Command { sfc /scannow } -TaskName "SFC"
} else {
    Write-Log "Skipping SFC."
}

# Task 4: Reset TCP/IP settings
$RunNETSH = Prompt-User "Do you want to reset TCP/IP settings?"
if ($RunNETSH -eq 'y') {
    Write-Log "Resetting TCP/IP settings..."
    Execute-Command -Command { netsh int ip reset } -TaskName "TCP/IP Reset"
} else {
    Write-Log "Skipping TCP/IP reset."
}

# Task 5: Network diagnostics
$RunNetworkDiagnostics = Prompt-User "Do you want to run network diagnostics?"
if ($RunNetworkDiagnostics -eq 'y') {
    Write-Log "Flushing DNS cache..."
    Execute-Command -Command { ipconfig /flushdns } -TaskName "Flush DNS" -MaxRetries 3 -RetryInterval 5

    Write-Log "Resetting Winsock catalog..."
    Execute-Command -Command { netsh winsock reset } -TaskName "Winsock Reset" -MaxRetries 3 -RetryInterval 5
} else {
    Write-Log "Skipping network diagnostics."
}

# Task 6: Disk Cleanup
$RunDiskCleanup = Prompt-User "Do you want to run Disk Cleanup?"
if ($RunDiskCleanup -eq 'y') {
    Write-Log "Running Disk Cleanup..."
    Execute-Command -Command { Cleanmgr.exe /sagerun:1 } -TaskName "Disk Cleanup"
} else {
    Write-Log "Skipping Disk Cleanup."
}

# Task 7: Defragmentation
$RunDefrag = Prompt-User "Do you want to defragment the hard drive?"
if ($RunDefrag -eq 'y') {
    Write-Log "Checking if drive C: is SSD..."
    $Drive = Get-PhysicalDisk | Where-Object { $_.FriendlyName -like "*" }
    if ($Drive.MediaType -eq 'SSD') {
        Write-Log "SSD detected. Skipping defragmentation."
    } else {
        Write-Log "Defragmenting C: drive..."
        Execute-Command -Command { defrag.exe C: /U /V } -TaskName "Defragmentation"
    }
} else {
    Write-Log "Skipping defragmentation."
}

# Task 8: Windows Update
$RunWindowsUpdate = Prompt-User "Do you want to check for Windows Updates?"
if ($RunWindowsUpdate -eq 'y') {
    Write-Log "Checking for Windows Updates..."
    # Install PSWindowsUpdate module if not installed
    if (-Not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log "Installing PSWindowsUpdate module..."
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
            Install-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
            Write-Log "PSWindowsUpdate module installed successfully."
        } catch {
            Write-Log "Failed to install PSWindowsUpdate module: $_" "ERROR"
        }
    }
    Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
    # Check and install updates
    Execute-Command -Command { Get-WindowsUpdate -AcceptAll -Install -AutoReboot } -TaskName "Windows Update" -MaxRetries 3 -RetryInterval 10
} else {
    Write-Log "Skipping Windows Update check."
}

# Task 9: Clean up temporary files
$RunTempCleanup = Prompt-User "Do you want to clean up temporary files?"
if ($RunTempCleanup -eq 'y') {
    Write-Log "Cleaning up temporary files..."
    Execute-Command -Command { Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue } -TaskName "Temporary Files Cleanup"
} else {
    Write-Log "Skipping temporary files cleanup."
}

Write-Log "Maintenance script completed."
Pause
Exit
