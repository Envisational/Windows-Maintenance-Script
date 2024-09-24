Windows Maintenance Script (PowerShell)
===============================================

This repository contains a PowerShell script designed to perform regular maintenance tasks on Windows systems. The script automates common system cleanup and repair operations to improve performance and fix common issues.

Table of Contents
-----------------

-   [Features](#features)
-   [Prerequisites](#prerequisites)
-   [Usage](#usage)
-   [Warnings](#warnings)
-   [Customization](#customization)
-   [Contributing](#contributing)
-   [License](#license)

Features
--------

-   **User Confirmation Prompts**: Allows you to choose which maintenance tasks to perform.
-   **Logging**:
    -   Implements different log levels (INFO, WARNING, ERROR) for better clarity.
    -   Archives old logs to prevent the log file from becoming too large.
-   **Error Handling**:
    -   Implements retry mechanisms for network-related commands in case of transient failures.
    -   Captures and logs the output of commands to provide more context when errors occur.
-   **Environment Checks**:
    -   Checks for sufficient disk space.
    -   Checks battery status (useful for laptops).
-   **Disk Maintenance**:
    -   Checks and repairs disk errors using `CHKDSK`.
    -   Defragments the hard drive (skips SSDs).
-   **System File Repair**:
    -   Repairs system files with `DISM` and `SFC`.
-   **Network Diagnostics**:
    -   Resets TCP/IP settings.
    -   Flushes DNS cache.
    -   Resets Winsock catalog.
-   **System Cleanup**:
    -   Cleans up unnecessary files and caches.
    -   Cleans up temporary files.
-   **Windows Update**:
    -   Checks for Windows Updates and installs them.
-   **Modular Design**: The script is modularized for easy maintenance and customization.

Prerequisites
-------------

-   **Administrator Privileges**: The script must be run with administrative rights.
-   **Windows PowerShell**: Version 5.1 or higher.
-   **Windows Operating System**: Compatible with Windows 7, 8, 10, and above.
-   **Disk Space**: Ensure sufficient disk space is available for disk cleanup and defragmentation.
-   **Internet Connection**: Required for Windows Update and installing PowerShell modules.

Usage
-----

1.  **Clone the Repository**

    ```bash
    git clone https://github.com/envisational/Windows-Maintenance-Script.git
    ```

3.  **Navigate to the Directory**

    ```bash
    cd windows-maintenance-script
    ```

4.  **Set Execution Policy**

    You may need to set the execution policy to allow running scripts:

    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

5.  **Run the Script as Administrator**

    -   Right-click on `maintenance.ps1` and select **Run with PowerShell**.

        Ensure you select **Run as Administrator**.

    -   Alternatively, run it from an elevated PowerShell prompt:

        ```powershell
        .\maintenance.ps1
        ```

6.  **Follow the Prompts**

    The script will prompt you to confirm whether you want to run each maintenance task. Enter `y` to proceed with a task or `n` to skip it.

Warnings
--------

-   **Data Loss Risk**: Some operations, like disk cleanup and temporary file deletion, may remove files you wish to keep. Ensure you have backups if necessary.
-   **System Performance**: Operations like `CHKDSK` and `defrag` can take a long time and may slow down your system during execution.
-   **Reboots**: Some commands may require a system reboot to complete repairs.
-   **Battery Power**: For laptops, ensure your device is plugged in to avoid running out of power during maintenance tasks.
-   **Execution Policy**: Be cautious when changing the PowerShell execution policy, and reset it to its original value if necessary.

Customization
-------------

You can customize the script to suit your needs:

-   **Enable or Disable Specific Tasks**: Edit the script to comment out any sections you do not wish to run automatically.
-   **Adjust Scheduling**: Use Windows Task Scheduler to run the script at convenient times.
-   **Log File Location**: Change the `$LogDirectory` variable to specify a different log file path.
-   **Modify Environment Checks**: Adjust disk space thresholds or remove battery checks as needed.
-   **Adjust Retry Mechanisms**: Modify `$MaxRetries` and `$RetryInterval` for network-related tasks.

Contributing
------------

Contributions are welcome! Please open an issue or submit a pull request if you have suggestions or improvements.

License
-------

This project is licensed under the MIT License. See the LICENSE file for details.
