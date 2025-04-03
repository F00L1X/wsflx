# Style Terminal for Windows (7-11)
# This script installs "Oh My Posh" and configures fonts for PowerShell, Windows Terminal, VS Code & Cursor
# Author: WSFLX
# Version: 1.1
# Compatible with Windows 7, 10, and 11
# IMPORTANT: This script requires administrative privileges

$ErrorActionPreference = "Stop"


function Write-ColorOutput {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$ForegroundColor = "White",
        [Parameter(Mandatory = $false)]
        [string]$NewLine = $true
    )
    if ($NewLine) {
        Write-Host $Message -ForegroundColor $ForegroundColor

    }
    else {

        Write-Host $Message -ForegroundColor $ForegroundColor -NoNewline
    }
}


# Default theme - will be overridden by user selection
function Select-OhMyPoshTheme {
    # Define available themes with descriptions
    $themes = @(
        @{Name = "cloud-context"; Description = "Clean cloud theme with contextual information" },
        @{Name = "craver"; Description = "Modern theme with git status and command execution time" },
        @{Name = "clean-detailed"; Description = "Minimal theme with essential information" },
        @{Name = "atomicBit"; Description = "Colorful theme with detailed git status" },
        @{Name = "atomic"; Description = "Compact and vibrant theme" },
        @{Name = "1_shell"; Description = "Simple single-line shell theme" }
    )

    # Display theme selection menu
    Write-ColorOutput "`n╭────────────────────────────────────╮" "Cyan"
    Write-ColorOutput "│      Oh My Posh Theme Selection     │" "Cyan"
    Write-ColorOutput "╰────────────────────────────────────╯" "Cyan"

    for ($i = 0; $i -lt $themes.Count; $i++) {
        Write-ColorOutput "[$($i+1)] $($themes[$i].Name)" "White"
        Write-ColorOutput "    $($themes[$i].Description)" "Gray"
    }

    Write-ColorOutput "`nSelect a theme [1-$($themes.Count)] (default: 1): " "Yellow" -
    $selection = Read-Host

    # Use default if empty or validate input
    if ([string]::IsNullOrWhiteSpace($selection)) {
        $selection = 1
    }
    elseif (-not ($selection -match '^\d+$') -or [int]$selection -lt 1 -or [int]$selection -gt $themes.Count) {
        Write-ColorOutput "Invalid selection. Using default theme." "Red"
        $selection = 1
    }

    $selectedTheme = $themes[$selection - 1].Name
    Write-ColorOutput "Selected theme: $selectedTheme" "Green"

    return $selectedTheme
}
$THEME = Select-OhMyPoshTheme
# Check for administrative privileges
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to safely check if a variable exists
function Test-VariableExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [bool](Get-Variable -Name $Name -ErrorAction SilentlyContinue)
}

# If not running as administrator, provide instructions and exit
if (-not (Test-Administrator)) {
    Write-Host "`n[ERROR] This script requires administrative privileges." -ForegroundColor Red
    Write-Host "`nPlease run this script in an administrative PowerShell window:" -ForegroundColor Yellow
    Write-Host "1. Right-click on PowerShell and select 'Run as administrator'" -ForegroundColor Yellow
    Write-Host "2. Navigate to the script location" -ForegroundColor Yellow
    Write-Host "3. Run the script again" -ForegroundColor Yellow
    Write-Host "`nScript execution terminated." -ForegroundColor Red

    # Pause to keep the window open so the user can read the message
    Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

function Test-CommandExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

# Add a cleanup function to remove temporary files
function Clear-TemporaryFiles {
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Paths = @(),

        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    # Common temporary locations used by this script
    $commonPaths = @(
        (Join-Path $env:TEMP "NerdFonts"),
        (Join-Path $env:TEMP "OhMyPosh"),
        (Join-Path $env:TEMP "style_terminal_w11.ps1")
    )

    # Combine specified paths with common paths
    $allPaths = $commonPaths + $Paths | Where-Object { $_ -and (Test-Path $_) }

    foreach ($path in $allPaths) {
        try {
            if (Test-Path $path) {
                # Force close any handles to files
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()

                # Remove the file or directory
                if ((Get-Item $path) -is [System.IO.DirectoryInfo]) {
                    Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                }
                else {
                    Remove-Item -Path $path -Force -ErrorAction Stop
                }

                if (-not $Silent) {
                    Write-ColorOutput "Cleaned up temporary file: $path" "Green"
                }
            }
        }
        catch {
            if (-not $Silent) {
                Write-ColorOutput "Failed to clean up: $path - $_" "Yellow"
            }
        }
    }
}

function Install-NerdFont {
    Write-ColorOutput "Installing Nerd Fonts..." "Yellow"
    $tempFolder = Join-Path $env:TEMP "NerdFonts"

    try {
        # First make sure Oh My Posh is installed
        if (-not (Test-CommandExists "oh-my-posh")) {
            Write-ColorOutput "Oh My Posh needs to be installed first before we can install fonts." "Yellow"
            $ohMyPoshInstalled = Install-OhMyPosh
            if (-not $ohMyPoshInstalled) {
                Write-ColorOutput "Failed to install Oh My Posh, cannot proceed with font installation." "Red"
                return $false
            }
        }

        # Use Oh My Posh's built-in font installation
        Write-ColorOutput "Installing Meslo font using Oh My Posh..." "Yellow"
        Invoke-Expression "oh-my-posh font install Meslo"

        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Meslo Nerd Font installed successfully using Oh My Posh." "Green"
            # Cleanup any temp files that might have been created by Oh My Posh
            Clear-TemporaryFiles -Silent
            return $true
        }
        else {
            Write-ColorOutput "Oh My Posh font installation returned an error. Exit code: $LASTEXITCODE" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "Failed during font installation: $_" "Red"
        return $false
    }
    finally {
        # Always make sure to clean up the temporary folder
        if (Test-Path $tempFolder) {
            Clear-TemporaryFiles -Paths @($tempFolder)
        }
    }
}

function Install-OhMyPosh {
    Write-ColorOutput "Checking for Oh My Posh..." "Yellow"

    # Check if Oh My Posh is already installed
    if (Test-CommandExists "oh-my-posh") {
        Write-ColorOutput "Oh My Posh is already installed." "Green"
        return $true
    }

    # Try to install using winget
    if (Test-CommandExists "winget") {
        try {
            Write-ColorOutput "Installing Oh My Posh using winget..." "Yellow"
            Write-ColorOutput "This may take a minute, please wait..." "Yellow"

            # Use direct command execution to ensure output is visible
            Write-ColorOutput "Running: winget install JanDeDobbeleer.OhMyPosh" "Cyan"

            # Set a script-level variable to track if we should try alternative methods
            $script:useAlternativeMethod = $false

            # Run the installation in a job so we can apply a timeout
            $job = Start-Job -ScriptBlock { winget install JanDeDobbeleer.OhMyPosh }

            # Wait for the job with timeout and display output in real-time
            $timeout = 90  # 90 seconds timeout
            $timer = [System.Diagnostics.Stopwatch]::StartNew()

            while (-not $job.HasMoreData -and $job.State -ne 'Completed' -and $timer.Elapsed.TotalSeconds -lt $timeout) {
                Start-Sleep -Seconds 1
            }

            # Get any output so far
            Receive-Job -Job $job

            # Check if the job completed or timed out
            if ($job.State -ne 'Completed' -and $timer.Elapsed.TotalSeconds -ge $timeout) {
                Write-ColorOutput "Winget installation is taking too long, attempting to stop..." "Yellow"
                Stop-Job -Job $job
                Remove-Job -Job $job -Force
                $script:useAlternativeMethod = $true
            }
            else {
                # Wait for job to complete and get all output
                while ($job.State -eq 'Running' -and $timer.Elapsed.TotalSeconds -lt $timeout) {
                    if ($job.HasMoreData) {
                        Receive-Job -Job $job
                    }
                    Start-Sleep -Seconds 1
                }

                # Final receive of any remaining output
                Receive-Job -Job $job
                Remove-Job -Job $job
            }

            if ($script:useAlternativeMethod) {
                Write-ColorOutput "Switching to direct installation method..." "Yellow"
                # Fall through to the direct installation method
            }
            else {
                # Refresh environment variables for current session
                RefreshEnvironmentVariables

                if (Test-CommandExists "oh-my-posh") {
                    Write-ColorOutput "Oh My Posh installed successfully using winget." "Green"
                    return $true
                }
                else {
                    Write-ColorOutput "Oh My Posh not found after winget installation. Trying direct installation..." "Yellow"
                    $script:useAlternativeMethod = $true
                }
            }
        }
        catch {
            Write-ColorOutput "Failed to install Oh My Posh using winget: $_" "Red"
            Write-ColorOutput "Trying alternative installation method..." "Yellow"
            $script:useAlternativeMethod = $true
        }
    }
    else {
        Write-ColorOutput "Winget not found. Using direct installation method..." "Yellow"
        $script:useAlternativeMethod = $true
    }

    # If winget installation failed or wasn't attempted, use direct installer
    if ($script:useAlternativeMethod) {
        # Alternative installation using direct installer
        try {
            Write-ColorOutput "Installing Oh My Posh using installer script..." "Yellow"

            Set-ExecutionPolicy Bypass -Scope Process -Force
            Write-ColorOutput "Downloading installer..." "Yellow"
            $installerContent = (New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1')
            Write-ColorOutput "Running installer..." "Yellow"
            Invoke-Expression $installerContent

            # Refresh environment variables for current session
            RefreshEnvironmentVariables

            if (Test-CommandExists "oh-my-posh") {
                Write-ColorOutput "Oh My Posh installed successfully using installer script." "Green"
                return $true
            }
            else {
                Write-ColorOutput "Failed to detect Oh My Posh after installation." "Red"

                # Last resort - try direct download and extraction
                try {
                    Write-ColorOutput "Attempting manual installation..." "Yellow"

                    # Download latest release
                    $tempFolder = Join-Path $env:TEMP "OhMyPosh"
                    if (-not (Test-Path $tempFolder)) {
                        New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
                    }

                    # Direct download the executable
                    $downloadUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe"
                    $exePath = Join-Path $tempFolder "oh-my-posh.exe"

                    (New-Object System.Net.WebClient).DownloadFile($downloadUrl, $exePath)

                    # Create a folder in the user's profile
                    $targetDir = Join-Path $env:USERPROFILE ".oh-my-posh"
                    if (-not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    }

                    # Copy the file
                    Copy-Item -Path $exePath -Destination (Join-Path $targetDir "oh-my-posh.exe") -Force

                    # Add to path
                    $env:Path = "$targetDir;$env:Path"
                    [Environment]::SetEnvironmentVariable("Path", $env:Path, "User")

                    if (Test-Path (Join-Path $targetDir "oh-my-posh.exe")) {
                        Write-ColorOutput "Oh My Posh installed manually to $targetDir" "Green"
                        return $true
                    }
                    else {
                        return $false
                    }
                }
                catch {
                    Write-ColorOutput "Manual installation failed: $_" "Red"
                    return $false
                }
            }
        }
        catch {
            Write-ColorOutput "Failed to install Oh My Posh: $_" "Red"
            return $false
        }
    }
}

# Add a function to refresh environment variables for the current session
function RefreshEnvironmentVariables {
    Write-ColorOutput "Refreshing environment variables for current session..." "Yellow"

    try {
        # Update PATH from the registry
        $paths = @(
            [Environment]::GetEnvironmentVariable("Path", "Machine"),
            [Environment]::GetEnvironmentVariable("Path", "User")
        ) | Where-Object { $_ }

        # Set the combined path back to the current process
        $env:Path = $paths -join ";"

        # Check common Oh My Posh installation locations if it's still not found
        $possibleLocations = @(
            "$env:LOCALAPPDATA\Programs\oh-my-posh\bin",
            "C:\Program Files\oh-my-posh\bin",
            "$env:USERPROFILE\AppData\Local\oh-my-posh"
        )

        foreach ($location in $possibleLocations) {
            if (Test-Path -Path $location) {
                if (-not $env:Path.Contains($location)) {
                    $env:Path = "$location;$env:Path"
                    Write-ColorOutput "Added Oh My Posh location to PATH: $location" "Green"
                }
            }
        }

        Write-ColorOutput "Environment variables refreshed." "Green"
        return $true
    }
    catch {
        Write-ColorOutput "Failed to refresh environment variables: $_" "Red"
        return $false
    }
}

# Function to create a simplified ISE-compatible prompt theme
function Get-SimplifiedISETheme {
    param(
        [Parameter(Mandatory = $false)]
        [string]$ThemeName = $THEME
    )

    # Map Oh My Posh theme names to simple color schemes for ISE
    $themeColorMap = @{
        "atomicBit" = @{
            "UserColor"    = "Cyan"
            "HostColor"    = "Green"
            "PathColor"    = "Yellow"
            "GitColor"     = "Magenta"
            "ErrorColor"   = "Red"
            "SuccessColor" = "Green"
            "PromptChar"   = ">"
        }
        "craver"    = @{
            "UserColor"    = "Magenta"
            "HostColor"    = "Blue"
            "PathColor"    = "Yellow"
            "GitColor"     = "Cyan"
            "ErrorColor"   = "Red"
            "SuccessColor" = "Green"
            "PromptChar"   = "λ"
        }
        "default"   = @{
            "UserColor"    = "Cyan"
            "HostColor"    = "Green"
            "PathColor"    = "Yellow"
            "GitColor"     = "Blue"
            "ErrorColor"   = "Red"
            "SuccessColor" = "Green"
            "PromptChar"   = ">"
        }
    }

    # Choose color scheme based on theme or fall back to default
    $colors = $themeColorMap[$ThemeName]
    if (-not $colors) {
        $colors = $themeColorMap["default"]
    }

    # Create the simplified prompt function for ISE
    $promptFunction = @"
function global:prompt {
    # Get the execution status of the last command
    `$lastExitCode = `$LASTEXITCODE
    `$lastCommandSuccess = `$?

    # Current user and hostname
    `$currentUser = [System.Environment]::UserName
    `$computerName = [System.Environment]::MachineName

    # Get current directory with home folder replacement
    `$currentPath = `$pwd.Path
    if (`$currentPath.StartsWith(`$HOME)) {
        `$currentPath = "~" + `$currentPath.Substring(`$HOME.Length)
    }

    # Git information (if available)
    `$gitBranch = ""
    try {
        `$gitCommand = Get-Command git -ErrorAction SilentlyContinue
        if (`$gitCommand) {
            `$gitBranch = git branch --show-current 2>`$null
            if (`$gitBranch) {
                `$gitBranch = " [" + `$gitBranch + "]"
            }
        }
    } catch {
        # Silently fail if git isn't available
    }

    # Build the prompt
    `$promptText = ""

    # Status indicator character and color
    `$statusChar = if (`$lastCommandSuccess) { "$($colors.PromptChar)" } else { "!" }
    `$statusColor = if (`$lastCommandSuccess) { "$($colors.SuccessColor)" } else { "$($colors.ErrorColor)" }

    # Build the prompt segments with colors
    `$promptText += Write-Host "`$(`$currentUser)@`$(`$computerName)" -NoNewline -ForegroundColor $($colors.UserColor)
    `$promptText += Write-Host " [" -NoNewline
    `$promptText += Write-Host "`$(`$currentPath)" -NoNewline -ForegroundColor $($colors.PathColor)
    `$promptText += Write-Host "]" -NoNewline

    if (`$gitBranch) {
        `$promptText += Write-Host "`$(`$gitBranch)" -NoNewline -ForegroundColor $($colors.GitColor)
    }

    # Check for admin privileges
    `$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (`$isAdmin) {
        `$promptText += Write-Host " (Admin)" -NoNewline -ForegroundColor $($colors.ErrorColor)
    }

    # Final prompt character with proper color
    `$promptText += Write-Host "`n`$(`$statusChar) " -NoNewline -ForegroundColor `$statusColor

    # Reset LASTEXITCODE to its previous value
    `$global:LASTEXITCODE = `$lastExitCode

    return " "
}

# Show a message once to indicate the simplified theme is active
Write-Host "ISE-compatible theme activated based on $ThemeName. Oh My Posh features are limited in ISE." -ForegroundColor Cyan
"@

    return $promptFunction
}

# Function to update profile content safely without regex issues
function Update-ProfileContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfilePath,

        [Parameter(Mandatory = $true)]
        [string]$NewConfiguration,

        [Parameter(Mandatory = $false)]
        [string]$ThemeName = $THEME
    )

    try {
        # Create a backup of the profile first
        $backupPath = "$ProfilePath.backup"
        Write-ColorOutput "Creating backup of profile at $backupPath" "Yellow"
        Copy-Item -Path $ProfilePath -Destination $backupPath -Force

        # Read the profile line by line instead of as one big string
        $profileLines = Get-Content -Path $ProfilePath -ErrorAction Stop

        # Check if file is empty
        if ($null -eq $profileLines -or $profileLines.Count -eq 0) {
            Write-ColorOutput "Profile is empty, writing new configuration" "Yellow"
            Set-Content -Path $ProfilePath -Value "# Oh My Posh Theme`n$NewConfiguration" -Force
            return $true
        }

        # Process the file
        $newContent = New-Object System.Collections.ArrayList
        $inOhMyPoshSection = $false
        $ohMyPoshSectionFound = $false
        $skipLinesUntil = -1

        for ($i = 0; $i -lt $profileLines.Count; $i++) {
            $line = $profileLines[$i]

            # Check if we should skip this line (part of an existing Oh My Posh section)
            if ($i -le $skipLinesUntil) {
                continue
            }

            # Look for the start of an Oh My Posh configuration section
            if ($line -match "^#\s*Oh My Posh Theme" -or
                $line -match "oh-my-posh init pwsh") {

                $ohMyPoshSectionFound = $true
                $inOhMyPoshSection = $true

                # Find the end of the Oh My Posh section
                $sectionEnd = $i
                for ($j = $i + 1; $j -lt $profileLines.Count; $j++) {
                    if ($profileLines[$j] -match "^#" -and $profileLines[$j] -notmatch "Oh My Posh") {
                        $sectionEnd = $j - 1
                        break
                    }
                    if ($j -eq $profileLines.Count - 1) {
                        $sectionEnd = $j
                    }
                }

                # Skip all lines in the existing Oh My Posh section
                $skipLinesUntil = $sectionEnd

                # Add our new configuration
                [void]$newContent.Add("# Oh My Posh Theme")
                foreach ($configLine in $NewConfiguration -split "`n") {
                    [void]$newContent.Add($configLine)
                }

                # Add a blank line after the section
                [void]$newContent.Add("")

                $inOhMyPoshSection = $false
            }
            else {
                # Add the line as-is
                [void]$newContent.Add($line)
            }
        }

        # If no Oh My Posh section was found, add it at the end
        if (-not $ohMyPoshSectionFound) {
            Write-ColorOutput "No existing Oh My Posh configuration found, adding new one" "Yellow"
            [void]$newContent.Add("")
            [void]$newContent.Add("# Oh My Posh Theme")
            foreach ($configLine in $NewConfiguration -split "`n") {
                [void]$newContent.Add($configLine)
            }
            [void]$newContent.Add("")
        }

        # Write the updated content back to the file
        $newContent | Set-Content -Path $ProfilePath -Force

        Write-ColorOutput "Profile updated successfully" "Green"
        return $true
    }
    catch {
        Write-ColorOutput "Error updating profile: $_" "Red"

        # Try to restore from backup if we made one
        if (Test-Path $backupPath) {
            Write-ColorOutput "Attempting to restore profile from backup..." "Yellow"
            try {
                Copy-Item -Path $backupPath -Destination $ProfilePath -Force
                Write-ColorOutput "Profile restored from backup" "Green"
            }
            catch {
                Write-ColorOutput "Failed to restore profile: $_" "Red"
            }
        }

        return $false
    }
}

function New-CleanProfile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfilePath,

        [Parameter(Mandatory = $true)]
        [string]$NewConfiguration,

        [Parameter(Mandatory = $false)]
        [switch]$ForceNewProfile
    )

    try {
        # Check if profile exists
        if (Test-Path $ProfilePath) {
            # Read the profile to check for corruption
            $profileContent = Get-Content -Path $ProfilePath -Raw -ErrorAction Stop

            # Check for profile corruption (multiple Oh My Posh configurations)
            $ohMyPoshCount = 0
            if ($profileContent -match "oh-my-posh init pwsh") {
                # Count occurrences of "oh-my-posh init pwsh"
                $ohMyPoshCount = ([regex]::Matches($profileContent, "oh-my-posh init pwsh")).Count

                if ($ohMyPoshCount -gt 1) {
                    Write-ColorOutput "Detected corrupted profile with $ohMyPoshCount Oh My Posh configurations" "Yellow"
                }
            }

            # If profile exists, always back it up and create a new one
            # Determine backup name with incremental numbering
            $profileDir = Split-Path -Parent $ProfilePath
            $profileName = Split-Path -Leaf $ProfilePath
            $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($profileName)
            $extension = [System.IO.Path]::GetExtension($profileName)

            # Find existing backups to determine next number
            $existingBackups = Get-ChildItem -Path $profileDir -Filter "$nameWithoutExt.backup*.ps1" -ErrorAction SilentlyContinue
            $maxNumber = 0

            if ($existingBackups) {
                foreach ($backup in $existingBackups) {
                    if ($backup.Name -match "\.backup(\d+)\.ps1$") {
                        $backupNumber = [int]$Matches[1]
                        if ($backupNumber -gt $maxNumber) {
                            $maxNumber = $backupNumber
                        }
                    }
                }
            }

            # Create new backup name with incremented number
            $newNumber = $maxNumber + 1
            $backupPath = Join-Path $profileDir "$nameWithoutExt.backup$newNumber$extension"

            # Backup the old profile
            Write-ColorOutput "Backing up existing profile to: $backupPath" "Yellow"
            Copy-Item -Path $ProfilePath -Destination $backupPath -Force

            # Create a new clean profile
            $newProfileContent = @"
# PowerShell Profile
# Created by Oh My Posh terminal styling script on $(Get-Date)

# Oh My Posh Theme
$NewConfiguration
"@

            # Write the new profile
            Set-Content -Path $ProfilePath -Value $newProfileContent -Force
            Write-ColorOutput "Created new clean profile at: $ProfilePath" "Green"
            Write-ColorOutput "Previous profile content is preserved in: $backupPath" "Cyan"

            return $true
        }
        else {
            # Profile doesn't exist, create a new one
            $profileDir = Split-Path -Parent $ProfilePath
            if (-not (Test-Path $profileDir)) {
                New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            }

            $newProfileContent = @"
# PowerShell Profile
# Created by Oh My Posh terminal styling script on $(Get-Date)

# Oh My Posh Theme
$NewConfiguration
"@

            Set-Content -Path $ProfilePath -Value $newProfileContent -Force
            Write-ColorOutput "Created new profile at: $ProfilePath" "Green"

            return $true
        }
    }
    catch {
        Write-ColorOutput "Error handling profile: $_" "Red"
        return $false
    }
}

# Update the Update-PowerShellProfile function to use the new method
function Update-PowerShellProfile {
    Write-ColorOutput "Configuring PowerShell profile..." "Yellow"

    try {
        # Store original $PROFILE for error reporting
        $originalProfile = $PROFILE

        # Safely get profile paths
        function Get-SafeProfilePath {
            param (
                [string]$ProfileType = "CurrentUserCurrentHost"
            )

            try {
                # Check if $PROFILE is a string or an object with properties
                if ($PROFILE -is [string]) {
                    # Handle case where $PROFILE is just a string
                    if ($ProfileType -eq "CurrentUserCurrentHost") {
                        return $PROFILE # Return the string value directly
                    }

                    # For other profile types, try to derive based on naming conventions
                    $profileDir = Split-Path -Parent $PROFILE
                    $fileName = Split-Path -Leaf $PROFILE

                    switch ($ProfileType) {
                        "CurrentUserAllHosts" {
                            return Join-Path $profileDir "profile.ps1"
                        }
                        "AllUsersCurrentHost" {
                            return Join-Path (Split-Path -Parent $profileDir) "Microsoft.PowerShell_profile.ps1"
                        }
                        "AllUsersAllHosts" {
                            return Join-Path (Split-Path -Parent $profileDir) "profile.ps1"
                        }
                        default {
                            return $PROFILE
                        }
                    }
                }
                else {
                    # Try to access property using different methods
                    if ($PROFILE.PSObject.Properties.Name -contains $ProfileType) {
                        return $PROFILE.$ProfileType
                    }
                    elseif ($ProfileType -eq "CurrentUserCurrentHost" -and
                             ($PROFILE | Get-Member -MemberType NoteProperty | Where-Object Name -eq "Path")) {
                        return $PROFILE.Path
                    }
                    else {
                        # Build path manually as fallback
                        $basePath = if ($PROFILE -is [string]) { $PROFILE } else { $HOME }
                        $profileDir = Join-Path $basePath "Documents\WindowsPowerShell"

                        switch ($ProfileType) {
                            "CurrentUserCurrentHost" {
                                return Join-Path $profileDir "Microsoft.PowerShell_profile.ps1"
                            }
                            "CurrentUserAllHosts" {
                                return Join-Path $profileDir "profile.ps1"
                            }
                            "AllUsersCurrentHost" {
                                return "C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1"
                            }
                            "AllUsersAllHosts" {
                                return "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1"
                            }
                            default {
                                return Join-Path $profileDir "Microsoft.PowerShell_profile.ps1"
                            }
                        }
                    }
                }
            }
            catch {
                # Absolute fallback
                Write-ColorOutput "Error determining profile path for $ProfileType`: $_" "Yellow"
                return Join-Path $HOME "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
            }
        }

        # More comprehensive profile detection that handles VSCode, Cursor and other editors
        Write-ColorOutput "Detecting PowerShell profiles..." "Yellow"

        # Get PowerShell version to help with detection
        $psVersion = $PSVersionTable.PSVersion
        $currentEdition = if ($PSVersionTable.PSEdition) { $PSVersionTable.PSEdition } else { "Desktop" }
        Write-ColorOutput "PowerShell: v$psVersion ($currentEdition edition)" "Cyan"

        # Get all possible profiles for the current user with proper error handling
        try {
            # First collect standard PowerShell profiles
            $possibleProfiles = @(
                # Current user profiles
                [PSCustomObject]@{
                    Path        = Get-SafeProfilePath -ProfileType "CurrentUserCurrentHost";
                    Type        = "CurrentUserCurrentHost";
                    Description = "Current user, current host";
                    IsDefault   = $true
                },
                [PSCustomObject]@{
                    Path        = Get-SafeProfilePath -ProfileType "CurrentUserAllHosts";
                    Type        = "CurrentUserAllHosts";
                    Description = "Current user, all hosts";
                    IsDefault   = $false
                }
            )

            # Add known editor-specific paths if they're not already included
            $knownEditorPaths = @{
                "VSCode" = @(
                    "$HOME\Documents\PowerShell\Microsoft.VSCode_profile.ps1",
                    "$HOME\.vscode\Microsoft.PowerShell_profile.ps1",
                    "$HOME\.vscode\PowerShell\Microsoft.PowerShell_profile.ps1"
                )
                "Cursor" = @(
                    "$HOME\Documents\PowerShell\Microsoft.Cursor_profile.ps1",
                    "$HOME\.cursor\Microsoft.PowerShell_profile.ps1",
                    "$HOME\.cursor\PowerShell\Microsoft.PowerShell_profile.ps1"
                )
            }

            # Add editor-specific paths to the possible profiles
            foreach ($editor in $knownEditorPaths.Keys) {
                foreach ($path in $knownEditorPaths[$editor]) {
                    # Normalize path format
                    $normalizedPath = $path -replace '\\', [System.IO.Path]::DirectorySeparatorChar

                    # Check if this path is already in our list
                    if (-not ($possibleProfiles | Where-Object { $_.Path -eq $normalizedPath })) {
                        $possibleProfiles += [PSCustomObject]@{
                            Path        = $normalizedPath;
                            Type        = "${editor}Profile";
                            Description = "$editor PowerShell profile";
                            IsDefault   = $false
                        }
                    }
                }
            }

            # Log all potential profiles we've found
            Write-ColorOutput "Found these potential profile paths:" "Cyan"
            foreach ($profile in $possibleProfiles) {
                $exists = Test-Path $profile.Path
                $statusMark = if ($exists) { "✓" } else { " " }
                Write-ColorOutput "  [$statusMark] $($profile.Path) ($($profile.Description))" "Cyan"
            }
        }
        catch {
            Write-ColorOutput "Error detecting potential profiles: $_" "Red"
            # Fallback to basic detection if the advanced method fails
            $possibleProfiles = @(
                [PSCustomObject]@{
                    Path        = $PROFILE.CurrentUserCurrentHost;
                    Type        = "CurrentUserCurrentHost";
                    Description = "Current user, current host";
                    IsDefault   = $true
                }
            )
            Write-ColorOutput "Falling back to basic profile: $($PROFILE.CurrentUserCurrentHost)" "Yellow"
        }

        # Patterns to identify profile types
        $iseProfilePattern = '\\Microsoft\.PowerShellISE_profile\.ps1$'
        $vscodeProfilePattern = '\\Microsoft\.VSCode_profile\.ps1$|\\\.vscode\\'
        $cursorProfilePattern = '\\Microsoft\.Cursor_profile\.ps1$|\\\.cursor\\'
        $regularProfilePattern = '\\Microsoft\.PowerShell_profile\.ps1$|\\profile\.ps1$'

        # Filter profiles based on priority
        # 1. First prefer existing regular profiles
        # 2. Then look for editor-specific existing profiles
        # 3. Finally fall back to default profile if none exist

        # Try to find an existing profile, preferring non-ISE profiles
        $existingProfiles = @($possibleProfiles |
            Where-Object { Test-Path $_.Path } |
            Where-Object { $_.Path -notmatch $iseProfilePattern })

        # Choose the best profile based on our context
        $profilePath = $null
        $profileType = "Default PowerShell profile"

        if ($existingProfiles -ne $null -and $existingProfiles.Count -gt 0) {
            # Prioritize different profiles based on what we're running in

            # Check if we're running in VSCode
            $inVSCode = $env:TERM_PROGRAM -eq "vscode" -or $host.Name -eq 'Visual Studio Code Host'

            # Check if we're running in Cursor (similar detection method to VSCode)
            $inCursor = $env:TERM_PROGRAM -eq "cursor" -or $host.Name -match 'Cursor'

            # Check if we're in Windows Terminal
            $inWindowsTerminal = $env:WT_SESSION -or $env:WT_PROFILE_ID

            # Select the appropriate profile based on where we're running
            $selectedProfile = $null

            if ($inVSCode) {
                # If we're in VSCode, prefer VSCode profile
                Write-ColorOutput "Detected running in VSCode" "Cyan"
                $selectedProfile = $existingProfiles | Where-Object { $_.Path -match $vscodeProfilePattern } | Select-Object -First 1
            }
            elseif ($inCursor) {
                # If we're in Cursor, prefer Cursor profile
                Write-ColorOutput "Detected running in Cursor" "Cyan"
                $selectedProfile = $existingProfiles | Where-Object { $_.Path -match $cursorProfilePattern } | Select-Object -First 1
            }
            elseif ($inWindowsTerminal) {
                # If we're in Windows Terminal, prefer regular profile
                Write-ColorOutput "Detected running in Windows Terminal" "Cyan"
                $selectedProfile = $existingProfiles | Where-Object { $_.Path -match $regularProfilePattern } | Select-Object -First 1
            }

            # If we didn't select a profile based on the environment, select the first regular profile
            if (-not $selectedProfile) {
                $selectedProfile = $existingProfiles | Where-Object { $_.Path -match $regularProfilePattern } | Select-Object -First 1
            }

            # If we still don't have a selection, just take the first existing profile
            if (-not $selectedProfile) {
                $selectedProfile = $existingProfiles | Select-Object -First 1
            }

            $profilePath = $selectedProfile.Path
            $profileType = "Existing $($selectedProfile.Type) profile"
            Write-ColorOutput "Selected profile: $profilePath" "Green"
        }
        else {
            # No existing profiles, create a default one
            $defaultProfile = $possibleProfiles | Where-Object { $_.IsDefault } | Select-Object -First 1
            if ($defaultProfile) {
                $profilePath = $defaultProfile.Path
                $profileType = "New $($defaultProfile.Type) profile"
                Write-ColorOutput "No existing profile found, will create: $profilePath" "Yellow"
            }
            else {
                # Last resort fallback
                $profilePath = $PROFILE.CurrentUserCurrentHost
                $profileType = "Fallback profile"
                Write-ColorOutput "Fallback to creating profile at: $profilePath" "Yellow"
            }
        }

        # Double-check we're not modifying an ISE profile
        if ($profilePath -match $iseProfilePattern) {
            Write-ColorOutput "Warning: Selected profile appears to be an ISE-specific profile: $profilePath" "Yellow"
            Write-ColorOutput "Switching to a regular PowerShell profile instead." "Yellow"

            # Force use of the standard CurrentUserCurrentHost profile
            $standardPath = Get-SafeProfilePath -ProfileType "CurrentUserCurrentHost"
            if ($standardPath -match "Microsoft\.PowerShellISE_profile\.ps1") {
                $standardPath = $standardPath -replace "Microsoft\.PowerShellISE_profile\.ps1", "Microsoft.PowerShell_profile.ps1"
            }
            $profilePath = $standardPath
            $profileType = "Standard PowerShell profile (switched from ISE)"
        }

        Write-ColorOutput "Using $profileType at: $profilePath" "Cyan"

        # Create PowerShell profile directory if it doesn't exist
        $profileDir = Split-Path -Parent $profilePath
        if (-not (Test-Path $profileDir)) {
            Write-ColorOutput "Creating profile directory: $profileDir" "Yellow"
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }

        # Create PowerShell profile if it doesn't exist
        if (-not (Test-Path $profilePath)) {
            Write-ColorOutput "Creating new profile file: $profilePath" "Yellow"
            New-Item -ItemType File -Path $profilePath -Force | Out-Null
        }

        # Configuration for Oh My Posh
        $ohMyPoshConfig = @'
# Oh My Posh Theme - Only initialize in compatible terminals, not in ISE
try {
    # Check if running in PowerShell ISE
    $isInISE = $false
    if (Get-Command Get-Variable -ErrorAction SilentlyContinue) {
        if (Get-Variable -Name psISE -ErrorAction SilentlyContinue) {
            $isInISE = $true
        }
    }
    if (-not $isInISE) {
        oh-my-posh init pwsh --config  ~/THEME_NAME.omp.json | Invoke-Expression
    } else {
        # PowerShell ISE doesn't support ANSI color codes used by Oh My Posh
        Write-Host "Oh My Posh is disabled in PowerShell ISE, using simplified theme instead" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Oh My Posh initialization failed: $_" -ForegroundColor Yellow
}
'@ -replace 'THEME_NAME', $THEME

        # Try to detect existing theme
        $existingTheme = $null
        if (Test-Path $profilePath) {
            $profileContent = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
            if ($profileContent -match 'oh-my-posh\s+init\s+pwsh\s+--config\s+[`"]?\$env:POSH_THEMES_PATH\\([^\.]+)\.omp\.json[`"]?') {
                $existingTheme = $matches[1]
                Write-ColorOutput "Found existing Oh My Posh configuration with theme: $existingTheme" "Cyan"
            }
        }

        # Update the regular profile using our new safe method
        Write-ColorOutput "Updating Oh My Posh configuration to include ISE compatibility..." "Yellow"
        if ($existingTheme -ne $THEME -and $null -ne $existingTheme) {
            Write-ColorOutput "Also updating theme from '$existingTheme' to '$THEME'..." "Yellow"
        }

        # Create a fresh clean profile
        $newProfileCreated = New-CleanProfile -ProfilePath $profilePath -NewConfiguration $ohMyPoshConfig -ForceNewProfile
        if (-not $newProfileCreated) {
            throw "Failed to create a clean PowerShell profile"
        }

        # Also create fresh profiles for all detected editors if they exist
        Write-ColorOutput "Ensuring clean profiles for all detected editors..." "Cyan"

        # List of editor-specific profile paths we found earlier
        $editorProfiles = $possibleProfiles | Where-Object {
            ($_.Path -match $vscodeProfilePattern -or $_.Path -match $cursorProfilePattern) -and
            (Test-Path $_.Path)
        }

        foreach ($editorProfile in $editorProfiles) {
            if ($editorProfile.Path -ne $profilePath) {
                # Don't process the same profile twice
                Write-ColorOutput "Creating clean profile for: $($editorProfile.Description)" "Cyan"
                $editorProfileCreated = New-CleanProfile -ProfilePath $editorProfile.Path -NewConfiguration $ohMyPoshConfig -ForceNewProfile
                if (-not $editorProfileCreated) {
                    Write-ColorOutput "Warning: Failed to create clean profile for $($editorProfile.Description)" "Yellow"
                }
            }
        }

        # Now also configure the ISE-specific profile with a simplified theme
        $currentUserPath = Get-SafeProfilePath -ProfileType "CurrentUserCurrentHost"
        $iseProfilePath = if ($currentUserPath -notmatch "Microsoft\.PowerShellISE_profile\.ps1") {
            $currentUserPath -replace "Microsoft\.PowerShell_profile\.ps1", "Microsoft.PowerShellISE_profile.ps1"
        }
        else {
            $currentUserPath
        }

        # If the path doesn't have the expected format, build it manually
        if (-not ($iseProfilePath -match "Microsoft\.PowerShellISE_profile\.ps1")) {
            $profileDir = Split-Path -Parent $currentUserPath
            $iseProfilePath = Join-Path $profileDir "Microsoft.PowerShellISE_profile.ps1"
        }

        # Check if the directory exists, if not create it
        $iseProfileDir = Split-Path -Parent $iseProfilePath
        if (-not (Test-Path $iseProfileDir)) {
            Write-ColorOutput "Creating ISE profile directory: $iseProfileDir" "Yellow"
            New-Item -ItemType Directory -Path $iseProfileDir -Force | Out-Null
        }

        # Create a simplified theme for ISE
        $iseThemeFunction = Get-SimplifiedISETheme -ThemeName $THEME

        # Read existing ISE profile content
        if (Test-Path $iseProfilePath) {
            Write-ColorOutput "Updating existing ISE profile with simplified theme..." "Yellow"

            # Get the ISE profile content line by line
            $iseProfileLines = Get-Content -Path $iseProfilePath -ErrorAction SilentlyContinue

            # Create new content excluding any existing prompt function
            $newIseContent = New-Object System.Collections.ArrayList
            $inPromptFunction = $false
            $promptFunctionFound = $false

            if ($null -ne $iseProfileLines -and $iseProfileLines.Count -gt 0) {
                for ($i = 0; $i -lt $iseProfileLines.Count; $i++) {
                    $line = $iseProfileLines[$i]

                    # Check for the start of a prompt function
                    if ($line -match "function\s+global:prompt\s*\{") {
                        $inPromptFunction = $true
                        $promptFunctionFound = $true
                        continue
                    }

                    # Check for the end of a function
                    if ($inPromptFunction -and $line -match "^\s*\}\s*$") {
                        $inPromptFunction = $false
                        continue
                    }

                    # Add the line if not in a prompt function
                    if (-not $inPromptFunction) {
                        [void]$newIseContent.Add($line)
                    }
                }
            }

            # Add the new theme function
            [void]$newIseContent.Add("")
            [void]$newIseContent.Add("# Theme-compatible PowerShell ISE prompt")
            foreach ($themeLine in $iseThemeFunction -split "`n") {
                [void]$newIseContent.Add($themeLine)
            }

            # Write the updated content back to the file
            $newIseContent | Set-Content -Path $iseProfilePath -Force
        }
        else {
            # Create new ISE profile
            Write-ColorOutput "Creating new ISE profile with simplified theme..." "Yellow"
            $newIseContent = "# PowerShell ISE Profile - Theme-compatible prompt`n$iseThemeFunction`n"
            Set-Content -Path $iseProfilePath -Value $newIseContent -Force
        }

        Write-ColorOutput "ISE profile configured with simplified theme at: $iseProfilePath" "Green"

        # Log what we modified
        Write-ColorOutput "Profiles updated:" "Cyan"
        Write-ColorOutput "  - Regular profile: $profilePath" "Cyan"
        Write-ColorOutput "  - ISE profile with simplified theme: $iseProfilePath" "Cyan"

        return $true
    }
    catch {
        Write-ColorOutput "Failed to update PowerShell profiles: $_" "Red"
        # Additional debug information using the preserved $originalProfile
        if ($originalProfile -ne $null) {
            try {
                Write-ColorOutput "Profile variable: $originalProfile" "Yellow"

                # Try to list all profile paths safely
                Write-ColorOutput "Available profile paths:" "Yellow"
                Write-ColorOutput "  CurrentUserCurrentHost: $($originalProfile.CurrentUserCurrentHost)" "Yellow"
                Write-ColorOutput "  CurrentUserAllHosts: $($originalProfile.CurrentUserAllHosts)" "Yellow"
                Write-ColorOutput "  AllUsersCurrentHost: $($originalProfile.AllUsersCurrentHost)" "Yellow"
                Write-ColorOutput "  AllUsersAllHosts: $($originalProfile.AllUsersAllHosts)" "Yellow"
            }
            catch {
                Write-ColorOutput "Error accessing profile paths: $_" "Yellow"
            }
        }
        else {
            Write-ColorOutput "Original profile variable is null" "Yellow"
        }

        # Check PowerShell version
        Write-ColorOutput "PowerShell version: $($PSVersionTable.PSVersion)" "Yellow"

        # Check if Windows Terminal
        if ($env:WT_SESSION -or $env:WT_PROFILE_ID) {
            Write-ColorOutput "Running in Windows Terminal" "Yellow"
        }

        return $false
    }
}

function Update-WindowsTerminalSettings {
    Write-ColorOutput "Checking for Windows Terminal settings..." "Yellow"

    $settingsPath = $null

    # Method 1: Search for Windows Terminal package directories using wildcard (Store version)
    try {
        $packageDir = Get-ChildItem -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal*" -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $packageDir) {
            $path = Join-Path -Path $dir.FullName -ChildPath "LocalState\settings.json"
            if (Test-Path -Path $path) {
                $settingsPath = $path
                Write-ColorOutput "Found Windows Terminal settings in Store package: $settingsPath" "Green"
                break
            }
        }
    }
    catch {
        Write-ColorOutput "Error searching for Windows Terminal package: $_" "Yellow"
    }

    # Method 2: Check common non-Store installation paths if not found yet
    if (-not $settingsPath) {
        $commonPaths = @(
            "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json",
            "$env:APPDATA\Microsoft\Windows Terminal\settings.json",
            "$env:USERPROFILE\AppData\Local\Microsoft\Windows Terminal\settings.json",
            "$env:USERPROFILE\scoop\apps\windows-terminal\current\settings.json"
        )

        foreach ($path in $commonPaths) {
            if (Test-Path -Path $path) {
                $settingsPath = $path
                Write-ColorOutput "Found Windows Terminal settings: $settingsPath" "Green"
                break
            }
        }
    }

    # Method 3: Last resort - try to search in common directories
    if (-not $settingsPath) {
        try {
            $possibleLocations = @(
                "$env:LOCALAPPDATA",
                "$env:APPDATA"
            )

            foreach ($location in $possibleLocations) {
                $foundFiles = Get-ChildItem -Path $location -Recurse -Filter "settings.json" -ErrorAction SilentlyContinue | Where-Object {
                    $content = Get-Content -Path $_.FullName -Raw -ErrorAction SilentlyContinue
                    $content -match "Windows Terminal" -or $content -match "profiles" -and $content -match "guid"
                }

                if ($foundFiles -and $foundFiles.Count -gt 0) {
                    $settingsPath = $foundFiles[0].FullName
                    Write-ColorOutput "Found possible Windows Terminal settings through search: $settingsPath" "Green"
                    break
                }
            }
        }
        catch {
            Write-ColorOutput "Error during deep search for Windows Terminal settings: $_" "Yellow"
        }
    }

    if (-not $settingsPath) {
        Write-ColorOutput "Windows Terminal settings file not found. Terminal might not be installed." "Cyan"
        return $true
    }

    try {
        # Load and parse the JSON file
        $settingsJson = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json

        # Check if font is already configured
        $fontConfigured = $false
        if ($settingsJson.profiles.defaults.font.face -eq "MesloLGM Nerd Font") {
            $fontConfigured = $true
        }

        if (-not $fontConfigured) {
            # Create font property if it doesn't exist
            if (-not $settingsJson.profiles.defaults.PSObject.Properties.Name -contains "font") {
                $settingsJson.profiles.defaults | Add-Member -Type NoteProperty -Name "font" -Value @{
                    face = "MesloLGM Nerd Font"
                }
            }
            else {
                $settingsJson.profiles.defaults.font.face = "MesloLGM Nerd Font"
            }

            # Save the changes back to the file
            $settingsJson | ConvertTo-Json -Depth 20 | Set-Content -Path $settingsPath
            Write-ColorOutput "Windows Terminal settings updated with Nerd Font." "Green"
        }
        else {
            Write-ColorOutput "Windows Terminal already configured with Nerd Font." "Cyan"
        }

        return $true
    }
    catch {
        Write-ColorOutput "Failed to update Windows Terminal settings: $_" "Red"
        return $false
    }
}

function Update-IDESettings {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("VSCode", "Cursor")]
        [string]$IDEType
    )

    Write-ColorOutput "Checking for $IDEType settings..." "Yellow"

    # Try to find settings in common locations based on IDE type
    $potentialPaths = @()

    if ($IDEType -eq "VSCode") {
        $potentialPaths = @(
            "$env:APPDATA\Code\User\settings.json",
            "$env:USERPROFILE\.vscode\settings.json"
        )
    }
    elseif ($IDEType -eq "Cursor") {
        $potentialPaths = @(
            "$env:APPDATA\Cursor\User\settings.json",
            "$env:USERPROFILE\.cursor\settings.json",
            "$env:APPDATA\Cursor\settings.json",
            "$env:USERPROFILE\.cursor-editor\settings.json"
        )
    }

    $settingsPath = $null
    foreach ($path in $potentialPaths) {
        if (Test-Path $path) {
            $settingsPath = $path
            break
        }
    }

    if (-not $settingsPath) {
        Write-ColorOutput "$IDEType settings file not found. $IDEType might not be installed." "Cyan"
        return $true
    }

    try {
        # Check if file exists but is empty
        if ((Get-Item $settingsPath).Length -eq 0) {
            $content = "{}"
        }
        else {
            $content = Get-Content -Path $settingsPath -Raw
        }

        # Clean the JSON content by removing any header comments or non-JSON content
        Write-ColorOutput "Parsing $IDEType settings file..." "Yellow"

        # Method 1: Try to find the first occurrence of '{' and extract from there
        try {
            $jsonStartIndex = $content.IndexOf('{')
            if ($jsonStartIndex -ge 0) {
                $cleanedContent = $content.Substring($jsonStartIndex)
                $settingsJson = $cleanedContent | ConvertFrom-Json
                Write-ColorOutput "Successfully parsed $IDEType settings using method 1." "Green"
            }
            else {
                throw "No JSON object found in settings file"
            }
        }
        catch {
            Write-ColorOutput "Method 1 failed: $_" "Yellow"

            # Method 2: Try to extract only valid JSON using regex
            try {
                # Extract everything between the first { and the last }
                if ($content -match '(?s)\{.*\}') {
                    $jsonMatch = $matches[0]
                    $settingsJson = $jsonMatch | ConvertFrom-Json
                    Write-ColorOutput "Successfully parsed $IDEType settings using method 2." "Green"
                }
                else {
                    throw "Could not extract valid JSON using regex"
                }
            }
            catch {
                Write-ColorOutput "Method 2 failed: $_" "Yellow"

                # Method 3: Remove all comment lines and try again
                try {
                    $lines = $content -split "`n" | Where-Object { -not $_.Trim().StartsWith('//') }
                    $cleanedContent = $lines -join "`n"
                    # Find JSON start and end
                    if ($cleanedContent -match '(?s)\{.*\}') {
                        $jsonMatch = $matches[0]
                        $settingsJson = $jsonMatch | ConvertFrom-Json
                        Write-ColorOutput "Successfully parsed $IDEType settings using method 3." "Green"
                    }
                    else {
                        throw "Failed to find valid JSON after removing comments"
                    }
                }
                catch {
                    Write-ColorOutput "All parsing methods failed. Creating minimal settings object." "Red"
                    # Create an empty object as a last resort
                    $settingsJson = [PSCustomObject]@{}
                }
            }
        }

        # Check if font is already configured
        $fontConfigured = $false
        if ($settingsJson.PSObject.Properties.Name -contains "terminal.integrated.fontFamily" -and
            $settingsJson."terminal.integrated.fontFamily" -eq "MesloLGM Nerd Font") {
            $fontConfigured = $true
        }

        if (-not $fontConfigured) {
            # Add font setting
            $settingsJson | Add-Member -Type NoteProperty -Name "terminal.integrated.fontFamily" -Value "MesloLGM Nerd Font" -Force

            # Preserve the original content structure when writing back
            # If we successfully parsed, we know where the JSON content starts
            if ($jsonStartIndex -ge 0) {
                $headerContent = $content.Substring(0, $jsonStartIndex)
                $newJson = $settingsJson | ConvertTo-Json -Depth 10
                $fullContent = $headerContent + $newJson
                Set-Content -Path $settingsPath -Value $fullContent
            }
            else {
                # Just write the JSON if we couldn't determine the header
                $settingsJson | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
            }

            Write-ColorOutput "$IDEType settings updated with Nerd Font." "Green"
        }
        else {
            Write-ColorOutput "$IDEType already configured with Nerd Font." "Cyan"
        }

        return $true
    }
    catch {
        Write-ColorOutput "Failed to update $IDEType settings: $_" "Red"
        return $false
    }
}

# Main script execution - enhanced error handling
try {
    Write-ColorOutput "Starting terminal styling script..." "Magenta"
    Write-ColorOutput "----------------------------------" "Magenta"

    # Prompt user to select a theme
    $THEME = Select-OhMyPoshTheme

    # Set strict error handling for better line number reporting
    Set-StrictMode -Version Latest

    # Create a status tracker
    $StatusTracker = [ordered]@{
        "Oh My Posh"         = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "Nerd Font"          = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "PowerShell Profile" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "Windows Terminal"   = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "VS Code"            = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "Cursor"             = @{ Status = $false; Message = "Not Started"; Color = "Red" }
    }

    # Step 1: Install Oh My Posh FIRST (before font installation)
    $StatusTracker."Oh My Posh".Message = "Installing..."
    $StatusTracker."Oh My Posh".Color = "Yellow"
    $ohMyPoshInstalled = Install-OhMyPosh
    if ($ohMyPoshInstalled) {
        $StatusTracker."Oh My Posh".Status = $true
        $StatusTracker."Oh My Posh".Message = "Installed (theme:$($THEME))"
        $StatusTracker."Oh My Posh".Color = "Green"
    }
    else {
        $StatusTracker."Oh My Posh".Message = "Failed"
        throw "Failed to install Oh My Posh. Aborting."
    }

    # Step 2: Install Nerd Fonts (after Oh My Posh is installed)
    $StatusTracker."Nerd Font".Message = "Installing..."
    $StatusTracker."Nerd Font".Color = "Yellow"
    $fontInstalled = Install-NerdFont
    if ($fontInstalled) {
        $StatusTracker."Nerd Font".Status = $true
        $StatusTracker."Nerd Font".Message = "Installed"
        $StatusTracker."Nerd Font".Color = "Green"
    }
    else {
        $StatusTracker."Nerd Font".Message = "Warning: Installation issues"
        $StatusTracker."Nerd Font".Color = "Yellow"
        Write-ColorOutput "Warning: Nerd Font installation might have issues. Continuing..." "Yellow"
    }

    # Step 3: Update PowerShell profile
    $StatusTracker."PowerShell Profile".Message = "Configuring..."
    $StatusTracker."PowerShell Profile".Color = "Yellow"
    $profileUpdated = Update-PowerShellProfile
    if ($profileUpdated) {
        $StatusTracker."PowerShell Profile".Status = $true
        $StatusTracker."PowerShell Profile".Message = "Configured"
        $StatusTracker."PowerShell Profile".Color = "Green"
    }
    else {
        $StatusTracker."PowerShell Profile".Message = "Failed"
        throw "Failed to update PowerShell profile. Aborting."
    }

    # Step 4: Update Windows Terminal settings
    $StatusTracker."Windows Terminal".Message = "Configuring..."
    $StatusTracker."Windows Terminal".Color = "Yellow"
    $terminalUpdated = Update-WindowsTerminalSettings
    if ($terminalUpdated) {
        $StatusTracker."Windows Terminal".Status = $true
        $StatusTracker."Windows Terminal".Message = "Configured"
        $StatusTracker."Windows Terminal".Color = "Green"
    }
    else {
        $StatusTracker."Windows Terminal".Message = "Failed"
        $StatusTracker."Windows Terminal".Color = "Red"
    }

    # Step 5: Update VS Code settings
    $StatusTracker."VS Code".Message = "Configuring..."
    $StatusTracker."VS Code".Color = "Yellow"
    $vscodeUpdated = Update-IDESettings -IDEType "VSCode"
    if ($vscodeUpdated) {
        $StatusTracker."VS Code".Status = $true
        $StatusTracker."VS Code".Message = "Configured"
        $StatusTracker."VS Code".Color = "Green"
    }
    else {
        $StatusTracker."VS Code".Message = "Failed"
        $StatusTracker."VS Code".Color = "Red"
    }

    # Step 6: Update Cursor settings
    $StatusTracker."Cursor".Message = "Configuring..."
    $StatusTracker."Cursor".Color = "Yellow"
    $cursorUpdated = Update-IDESettings -IDEType "Cursor"
    if ($cursorUpdated) {
        $StatusTracker."Cursor".Status = $true
        $StatusTracker."Cursor".Message = "Configured"
        $StatusTracker."Cursor".Color = "Green"
    }
    else {
        $StatusTracker."Cursor".Message = "Failed"
        $StatusTracker."Cursor".Color = "Red"
    }

    # Print stylish status dashboard
    Write-ColorOutput "`n----------------------------------" "Magenta"
    Write-ColorOutput "     TERMINAL STYLING REPORT     " "Magenta"
    Write-ColorOutput "----------------------------------" "Magenta"

    foreach ($component in $StatusTracker.Keys) {
        $statusSymbol = if ($StatusTracker[$component].Status) { "[✓]" } else { "[x]" }
        $statusMessage = $StatusTracker[$component].Message
        $statusColor = $StatusTracker[$component].Color

        # Calculate padding for alignment
        $padding = 20 - $component.Length
        $paddingString = " " * $padding

        Write-Host "  $statusSymbol " -NoNewline -ForegroundColor $statusColor
        Write-Host "$component$paddingString" -NoNewline
        Write-Host " | " -NoNewline -ForegroundColor Gray
        Write-Host " $statusMessage" -ForegroundColor $statusColor
    }

    # Calculate overall success percentage
    $successCount = ($StatusTracker.Values | Where-Object { $_.Status -eq $true }).Count
    $totalCount = $StatusTracker.Count
    $successPercentage = [math]::Round(($successCount / $totalCount) * 100)

    Write-ColorOutput "----------------------------------" "Magenta"
    Write-ColorOutput "  Overall Success: $successPercentage% ($successCount/$totalCount)" -ForegroundColor $(if ($successPercentage -eq 100) { "Green" } elseif ($successPercentage -ge 80) { "Yellow" } else { "Red" })
    Write-ColorOutput "----------------------------------" "Magenta"
    Write-ColorOutput "Please restart your terminal or PowerShell to see the changes." "Cyan"

    # Final cleanup of all temporary files
    Write-ColorOutput "`nCleaning up temporary files..." "Yellow"
    Clear-TemporaryFiles
    Write-ColorOutput "Cleanup complete." "Green"

}
catch {
    # Enhanced error reporting with line numbers
    $errorRecord = $_
    $exception = $errorRecord.Exception
    $message = $exception.Message

    Write-ColorOutput "`n========== ERROR DETAILS ==========" "Red"
    Write-ColorOutput "An error occurred: $message" "Red"

    # Try to get exact error location
    if ($errorRecord.InvocationInfo) {
        $line = $errorRecord.InvocationInfo.ScriptLineNumber
        $positionMessage = $errorRecord.InvocationInfo.PositionMessage
        $command = $errorRecord.InvocationInfo.Line.Trim()

        Write-ColorOutput "Error occurred on line: $line" "Red"
        Write-ColorOutput "Command: $command" "Red"
        Write-ColorOutput "Position: $positionMessage" "Red"
    }

    # Get call stack if available
    if ($errorRecord.ScriptStackTrace) {
        Write-ColorOutput "`nCall Stack:" "Yellow"
        Write-ColorOutput $errorRecord.ScriptStackTrace "Yellow"
    }

    # Get full error record details
    Write-ColorOutput "`nFull Error Record:" "Yellow"
    Write-ColorOutput ($errorRecord | Format-List * -Force | Out-String) "Yellow"

    Write-ColorOutput "`nPlease try running the script again or manually complete the remaining steps." "Red"
    Write-ColorOutput "For support, please provide the above error details." "Red"
    Write-ColorOutput "===================================`n" "Red"

    # Even if there's an error, try to clean up temporary files
    Write-ColorOutput "Cleaning up temporary files..." "Yellow"
    Clear-TemporaryFiles -Silent

    exit 1
}

