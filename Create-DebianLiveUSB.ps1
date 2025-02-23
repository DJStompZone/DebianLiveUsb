<#
.SYNOPSIS
    Creates a Debian Bookworm Live USB using Rufus in command-line mode.

.DESCRIPTION
    - Downloads Rufus Portable if not present.
    - Downloads the latest Debian Bookworm ISO if not found.
    - Prompts the user to select a USB drive.
    - Uses Rufus (command-line mode) to format the USB and write the ISO.
    - Runs Rufus in noninteractive mode to automate the process.

.NOTES
    File Name  : Create-DebianLiveUSB.ps1
    Author     : DJ Stomp <85457381+DJStompZone@users.noreply.github.com>
    License    : MIT
    Repository : https://github.com/djstompzone/DebianLiveUSB
    Dependencies: Rufus.exe (auto-downloaded), Debian ISO (auto-downloaded if missing)
#>

# Load Windows Forms for GUI dialogs
Add-Type -AssemblyName System.Windows.Forms

$rufusUrl = "https://github.com/pbatard/rufus/releases/download/v4.6/rufus-4.6p.exe"
$rufusFile = ".\rufus.exe"
$debianIsoUrl = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.9.0-amd64-netinst.iso"
$debianIsoFile = ".\debian-12.9.0-amd64-netinst.iso"

function Download-File {
    param (
        [string]$url,
        [string]$filePath
    )

    Write-Host "Downloading $filePath..."
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $filePath)
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to download $filePath", "Error", "OK", "Error")
        return $false
    }
}

function Ensure-Rufus {
    <#
    .SYNOPSIS
        Ensures Rufus is available by downloading it if missing.

    .OUTPUTS
        [bool] - Returns $true if Rufus is available.
    #>
    if (-not (Test-Path $rufusFile)) {
        return (Download-File -url $rufusUrl -filePath $rufusFile)
    }
    return $true
}

function Ensure-DebianISO {
    <#
    .SYNOPSIS
        Ensures the Debian netinst ISO is available by downloading it if missing.

    .OUTPUTS
        [bool] - Returns $true if the ISO is available.
    #>
    if (-not (Test-Path $debianIsoFile)) {
        return (Download-File -url $debianIsoUrl -filePath $debianIsoFile)
    }
    return $true
}

function Get-USB-Drives {
    <#
    .SYNOPSIS
        Retrieves a list of removable USB drives.

    .OUTPUTS
        [PSCustomObject[]] - A list of removable drives.
    #>
    Get-WmiObject Win32_DiskDrive | Where-Object { $_.MediaType -eq "Removable Media" } |
        Select-Object DeviceID, Model
}

function Show-DriveSelectionDialog {
    <#
    .SYNOPSIS
        Displays a GUI for USB drive selection.

    .OUTPUTS
        [string] - Selected USB drive.
    #>
    $drives = Get-USB-Drives
    if (-not $drives) {
        [System.Windows.Forms.MessageBox]::Show("No USB drives detected.", "Error", "OK", "Error")
        return $null
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select USB Drive"
    $form.Size = New-Object System.Drawing.Size(350, 200)
    $form.StartPosition = "CenterScreen"

    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point(10, 10)
    $comboBox.Size = New-Object System.Drawing.Size(300, 20)

    foreach ($drive in $drives) {
        $comboBox.Items.Add("$($drive.DeviceID) - $($drive.Model)")
    }
    $comboBox.SelectedIndex = 0
    $form.Controls.Add($comboBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(10, 50)
    $okButton.Add_Click({ $form.Tag = $comboBox.SelectedItem; $form.Close() })
    $form.Controls.Add($okButton)

    $form.ShowDialog()
    return $form.Tag
}

# Main Execution
Write-Host "`n=== Debian Bookworm Live USB Creator ===`n"

# Ensure Rufus & Debian ISO exist
if (-not (Ensure-Rufus)) { exit }
if (-not (Ensure-DebianISO)) { exit }

$selectedDrive = Show-DriveSelectionDialog
if (-not $selectedDrive) { exit }

$usbDrive = $selectedDrive.Split(" ")[0]

Write-Host "`nRunning Rufus to create the Debian Bookworm Live USB..."
Start-Process -Wait -NoNewWindow $rufusFile -ArgumentList "--device $usbDrive --iso `"$debianIsoFile`" --format fat32 --noninteractive"

[System.Windows.Forms.MessageBox]::Show("Debian Bookworm Live USB has been created!", "Success", "OK", "Information")
Write-Host "`n=== Live USB Creation Completed! ===`n"
