# Style Terminal for Windows (7-11)
# This script installs "Oh My Posh" and configures fonts for PowerShell, Windows Terminal, VS Code & Cursor
# Author: WSFLX
# Version: 1.1
# Compatible with Windows 7, 10, and 11
# IMPORTANT: This script requires administrative privileges

$ErrorActionPreference = "Stop"
$THEME = "atomicBit" # or craver or anything, refer to: https://ohmyposh.dev/docs/themes

# Check for administrative privileges
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to safely check if a variable exists
function Test-VariableExists {
    param (
        [Parameter(Mandatory=$true)]
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

function Write-ColorOutput {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$ForegroundColor = "White"
    )

    Write-Host $Message -ForegroundColor $ForegroundColor
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
                } else {
                    Remove-Item -Path $path -Force -ErrorAction Stop
                }

                if (-not $Silent) {
                    Write-ColorOutput "Cleaned up temporary file: $path" "Green"
                }
            }
        } catch {
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
        } else {
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
            } else {
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
            } else {
                # Refresh environment variables for current session
                RefreshEnvironmentVariables

                if (Test-CommandExists "oh-my-posh") {
                    Write-ColorOutput "Oh My Posh installed successfully using winget." "Green"
                    return $true
                } else {
                    Write-ColorOutput "Oh My Posh not found after winget installation. Trying direct installation..." "Yellow"
                    $script:useAlternativeMethod = $true
                }
            }
        } catch {
            Write-ColorOutput "Failed to install Oh My Posh using winget: $_" "Red"
            Write-ColorOutput "Trying alternative installation method..." "Yellow"
            $script:useAlternativeMethod = $true
        }
    } else {
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
            } else {
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
                    } else {
                        return $false
                    }
                } catch {
                    Write-ColorOutput "Manual installation failed: $_" "Red"
                    return $false
                }
            }
        } catch {
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

function Update-PowerShellProfile {
    Write-ColorOutput "Configuring PowerShell profile..." "Yellow"

    try {
        # Safe ISE detection that works on Windows 10
        $inPowerShellISE = $false
        try {
            # First check if the variable exists before accessing it
            if (Test-VariableExists -Name "psISE") {
                $inPowerShellISE = $null -ne (Get-Variable -Name "psISE" -ValueOnly)
            }
            # Secondary detection method based on process name
            if (-not $inPowerShellISE) {
                $processName = (Get-Process -Id $PID).ProcessName
                $inPowerShellISE = $processName -eq "powershell_ise"
            }
        }
        catch {
            Write-ColorOutput "ISE detection had an issue, assuming regular PowerShell: $_" "Yellow"
            $inPowerShellISE = $false
        }

        if ($inPowerShellISE) {
            Write-ColorOutput "Detected PowerShell ISE environment." "Cyan"
            Write-ColorOutput "Note: PowerShell ISE does not support ANSI color codes used by Oh My Posh." "Yellow"
        }

        # Determine the correct profile path based on the environment
        $profilePath = $PROFILE
        $profileType = "Default PowerShell profile"

        # Check if we're running in Windows Terminal
        $inWindowsTerminal = $env:WT_SESSION -or $env:WT_PROFILE_ID
        if ($inWindowsTerminal) {
            Write-ColorOutput "Detected Windows Terminal environment." "Cyan"
            $profileType = "Windows Terminal PowerShell profile"

            # For Windows Terminal, we might need to use a different profile path
            # Get potential profile paths for Windows Terminal
            $potentialProfiles = @(
                $PROFILE,
                $PROFILE.CurrentUserCurrentHost,
                $PROFILE.CurrentUserAllHosts,
                $PROFILE.AllUsersCurrentHost,
                $PROFILE.AllUsersAllHosts
            ) | Select-Object -Unique

            # Find the first existing profile or create one
            $existingProfile = $potentialProfiles | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($existingProfile) {
                $profilePath = $existingProfile
                Write-ColorOutput "Using existing profile: $profilePath" "Cyan"
            } else {
                # Default to CurrentUserCurrentHost if none exists
                $profilePath = $PROFILE.CurrentUserCurrentHost
                Write-ColorOutput "No existing profile found, will create: $profilePath" "Yellow"
            }
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
            $profileContent = ""
        } else {
            # Read existing profile content with extra error handling
            try {
                $profileContent = Get-Content -Path $profilePath -Raw -ErrorAction Stop
                if ([string]::IsNullOrWhiteSpace($profileContent)) {
                    Write-ColorOutput "Profile exists but is empty." "Yellow"
                    $profileContent = ""
                }
            } catch {
                Write-ColorOutput "Error reading profile (will create empty profile): $_" "Yellow"
                $profileContent = ""
            }
        }

        # Always use the ISE-aware Oh My Posh configuration
        $newOhMyPoshConfig = @"
# Oh My Posh Theme - Only initialize in compatible terminals, not in ISE
try {
    # Check if running in PowerShell ISE
    `$isInISE = `$false
    if (Get-Command Get-Variable -ErrorAction SilentlyContinue) {
        if (Get-Variable -Name psISE -ErrorAction SilentlyContinue) {
            `$isInISE = `$true
        }
    }

    if (-not `$isInISE) {
        # Only initialize Oh My Posh in regular console
        oh-my-posh init pwsh --config "`$env:POSH_THEMES_PATH\$($THEME).omp.json" | Invoke-Expression
    } else {
        # PowerShell ISE doesn't support ANSI color codes used by Oh My Posh
        Write-Host "Oh My Posh is disabled in PowerShell ISE" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Oh My Posh initialization failed: `$_" -ForegroundColor Yellow
}
"@

        $ohMyPoshConfigured = $false
        $existingTheme = $null

        # Try to detect existing Oh My Posh configuration and extract theme
        if (-not [string]::IsNullOrWhiteSpace($profileContent)) {
            # Look for the Oh My Posh init line with regex to extract theme
            $ohMyPoshPattern = 'oh-my-posh\s+init\s+pwsh\s+--config\s+[`"]?\$env:POSH_THEMES_PATH\\([^\.]+)\.omp\.json[`"]?\s+\|\s+Invoke-Expression'
            if ($profileContent -match $ohMyPoshPattern) {
                $ohMyPoshConfigured = $true
                $existingTheme = $matches[1]
                Write-ColorOutput "Found existing Oh My Posh configuration with theme: $existingTheme" "Cyan"

                # Always update the configuration to include ISE check
                Write-ColorOutput "Updating Oh My Posh configuration to include ISE compatibility..." "Yellow"
                if ($existingTheme -ne $THEME) {
                    Write-ColorOutput "Also updating theme from '$existingTheme' to '$THEME'..." "Yellow"
                }

                # Replace the existing Oh My Posh configuration with the new one
                $updatedContent = $profileContent

                # First try to update the entire Oh My Posh section
                $sectionPattern = "(?ms)# Oh My Posh Theme.*?(?=\r?\n[^#]|\Z)"
                if ($profileContent -match $sectionPattern) {
                    $updatedContent = $profileContent -replace $sectionPattern, "# Oh My Posh Theme`n$newOhMyPoshConfig"
                }
                # If that didn't work, try to update just the init line
                elseif ($updatedContent -eq $profileContent) {
                    $updatedContent = $profileContent -replace $ohMyPoshPattern, ($newOhMyPoshConfig -replace "# Oh My Posh Theme.*\r?\n", "")
                }

                # If both previous attempts failed, append the new config
                if ($updatedContent -eq $profileContent) {
                    Write-ColorOutput "Could not update existing Oh My Posh configuration, will append new one" "Yellow"
                    $updatedContent = $profileContent + "`n# Oh My Posh Theme`n$newOhMyPoshConfig`n"
                }

                Set-Content -Path $profilePath -Value $updatedContent -Force
                Write-ColorOutput "Oh My Posh configuration updated with ISE compatibility." "Green"
            } elseif ($profileContent -match "oh-my-posh init pwsh") {
                # Found Oh My Posh but couldn't parse theme, more generic pattern
                $ohMyPoshConfigured = $true
                Write-ColorOutput "Found existing Oh My Posh configuration but couldn't detect theme." "Yellow"
                Write-ColorOutput "Updating configuration with ISE compatibility..." "Yellow"

                # Try to replace the line with a more generic pattern
                $genericPattern = '(?ms)# Oh My Posh Theme.*?(?=\r?\n[^#]|\Z)|oh-my-posh\s+init\s+pwsh.*\|\s+Invoke-Expression'
                $updatedContent = $profileContent -replace $genericPattern, "# Oh My Posh Theme`n$newOhMyPoshConfig"

                if ($updatedContent -ne $profileContent) {
                    Set-Content -Path $profilePath -Value $updatedContent -Force
                    Write-ColorOutput "Oh My Posh configuration updated with ISE compatibility." "Green"
                } else {
                    # Couldn't replace with regex, just add the new config
                    Add-Content -Path $profilePath -Value "`n# Oh My Posh Theme`n$newOhMyPoshConfig`n" -Force
                    Write-ColorOutput "Added new Oh My Posh configuration with ISE compatibility." "Green"
                }
            } else {
                # No Oh My Posh config found
                $ohMyPoshConfigured = $false
            }
        } else {
            # Profile is empty
            Write-ColorOutput "Profile is empty, will add new Oh My Posh configuration." "Yellow"
            $ohMyPoshConfigured = $false
        }

        # If Oh My Posh is not configured yet, add it
        if (-not $ohMyPoshConfigured) {
            $newContent = if ([string]::IsNullOrWhiteSpace($profileContent)) {
                "# Oh My Posh Theme`n$newOhMyPoshConfig`n"
            } else {
                "`n# Oh My Posh Theme`n$newOhMyPoshConfig`n"
            }

            Add-Content -Path $profilePath -Value $newContent -Force
            Write-ColorOutput "Oh My Posh configured in PowerShell profile with theme: $THEME and ISE compatibility." "Green"
        }

        return $true
    } catch {
        Write-ColorOutput "Failed to update PowerShell profile: $_" "Red"
        # Additional debug information
        Write-ColorOutput "Profile variable: $PROFILE" "Yellow"

        # Try to list all profile paths
        Write-ColorOutput "Available profile paths:" "Yellow"
        Write-ColorOutput "  CurrentUserCurrentHost: $($PROFILE.CurrentUserCurrentHost)" "Yellow"
        Write-ColorOutput "  CurrentUserAllHosts: $($PROFILE.CurrentUserAllHosts)" "Yellow"
        Write-ColorOutput "  AllUsersCurrentHost: $($PROFILE.AllUsersCurrentHost)" "Yellow"
        Write-ColorOutput "  AllUsersAllHosts: $($PROFILE.AllUsersAllHosts)" "Yellow"

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
    } catch {
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
        } catch {
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
            } else {
                $settingsJson.profiles.defaults.font.face = "MesloLGM Nerd Font"
            }

            # Save the changes back to the file
            $settingsJson | ConvertTo-Json -Depth 20 | Set-Content -Path $settingsPath
            Write-ColorOutput "Windows Terminal settings updated with Nerd Font." "Green"
        } else {
            Write-ColorOutput "Windows Terminal already configured with Nerd Font." "Cyan"
        }

        return $true
    } catch {
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
    } elseif ($IDEType -eq "Cursor") {
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
        } else {
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
            } else {
                throw "No JSON object found in settings file"
            }
        } catch {
            Write-ColorOutput "Method 1 failed: $_" "Yellow"

            # Method 2: Try to extract only valid JSON using regex
            try {
                # Extract everything between the first { and the last }
                if ($content -match '(?s)\{.*\}') {
                    $jsonMatch = $matches[0]
                    $settingsJson = $jsonMatch | ConvertFrom-Json
                    Write-ColorOutput "Successfully parsed $IDEType settings using method 2." "Green"
                } else {
                    throw "Could not extract valid JSON using regex"
                }
            } catch {
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
                    } else {
                        throw "Failed to find valid JSON after removing comments"
                    }
                } catch {
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
            } else {
                # Just write the JSON if we couldn't determine the header
                $settingsJson | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
            }

            Write-ColorOutput "$IDEType settings updated with Nerd Font." "Green"
        } else {
            Write-ColorOutput "$IDEType already configured with Nerd Font." "Cyan"
        }

        return $true
    } catch {
        Write-ColorOutput "Failed to update $IDEType settings: $_" "Red"
        return $false
    }
}

# Main script execution - enhanced error handling
try {
    Write-ColorOutput "Starting terminal styling script..." "Magenta"
    Write-ColorOutput "----------------------------------" "Magenta"

    # Set strict error handling for better line number reporting
    Set-StrictMode -Version Latest

    # Create a status tracker
    $StatusTracker = [ordered]@{
        "Oh My Posh" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "Nerd Font" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "PowerShell Profile" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "Windows Terminal" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "VS Code" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "Cursor" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
    }

    # Step 1: Install Oh My Posh FIRST (before font installation)
    $StatusTracker."Oh My Posh".Message = "Installing..."
    $StatusTracker."Oh My Posh".Color = "Yellow"
    $ohMyPoshInstalled = Install-OhMyPosh
    if ($ohMyPoshInstalled) {
        $StatusTracker."Oh My Posh".Status = $true
        $StatusTracker."Oh My Posh".Message = "Installed (theme:$($THEME))"
        $StatusTracker."Oh My Posh".Color = "Green"
    } else {
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
    } else {
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
    } else {
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
    } else {
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
    } else {
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
    } else {
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

} catch {
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

