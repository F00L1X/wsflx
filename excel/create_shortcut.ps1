# Create a shortcut to launch the CSV Duplicate Remover GUI

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$PSScriptRoot\CSV Duplicate Remover.lnk")

# Target: PowerShell executable
$Shortcut.TargetPath = "powershell.exe"

# Arguments: Bypass execution policy and run the GUI script
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSScriptRoot\RemoveDuplicates-GUI.ps1`""

# Working directory
$Shortcut.WorkingDirectory = $PSScriptRoot

# Description
$Shortcut.Description = "CSV Duplicate Remover with Encoding Fix"

# Icon (using PowerShell icon, or you can specify a custom .ico file)
$Shortcut.IconLocation = "powershell.exe,0"

# Save the shortcut
$Shortcut.Save()

Write-Host "Shortcut created successfully: CSV Duplicate Remover.lnk" -ForegroundColor Green
Write-Host "You can now double-click this shortcut to launch the application." -ForegroundColor Cyan
