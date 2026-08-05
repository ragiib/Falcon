<#
.SYNOPSIS
Setup Windows Shortcuts for Falcon Launcher

.DESCRIPTION
Creates Desktop and Start Menu shortcuts pointing to FalconLauncher.ps1.
#>

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LauncherScript = Join-Path $ScriptDir "FalconLauncher.ps1"
$IconPath = Join-Path $ScriptDir "falcon.ico"

# If icon doesn't exist, we will use a generic one or create a dummy file
if (-not (Test-Path $IconPath)) {
    Write-Host "falcon.ico not found, using generic icon."
    $IconPath = "%SystemRoot%\System32\SHELL32.dll, 13" # A star icon or generic app icon
}

$WshShell = New-Object -ComObject WScript.Shell

# 1. Desktop Shortcut
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopShortcut = Join-Path $DesktopPath "Falcon AI.lnk"

Write-Host "Creating Desktop Shortcut: $DesktopShortcut"
$Shortcut = $WshShell.CreateShortcut($DesktopShortcut)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$LauncherScript`""
$Shortcut.WorkingDirectory = $ScriptDir
$Shortcut.IconLocation = $IconPath
$Shortcut.Description = "Falcon AI Development Launcher"
$Shortcut.Save()

# 2. Start Menu Shortcut
$StartMenuPath = [Environment]::GetFolderPath("StartMenu")
$ProgramsPath = Join-Path $StartMenuPath "Programs"
$StartMenuShortcut = Join-Path $ProgramsPath "Falcon AI.lnk"

Write-Host "Creating Start Menu Shortcut: $StartMenuShortcut"
$Shortcut = $WshShell.CreateShortcut($StartMenuShortcut)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$LauncherScript`""
$Shortcut.WorkingDirectory = $ScriptDir
$Shortcut.IconLocation = $IconPath
$Shortcut.Description = "Falcon AI Development Launcher"
$Shortcut.Save()

Write-Host "Shortcuts created successfully!" -ForegroundColor Green
