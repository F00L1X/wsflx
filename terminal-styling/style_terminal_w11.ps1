# Style Terminal for Windows (7-11)
# This script installs Oh My Posh and configures fonts for PowerShell, Windows Terminal, and VS Code
# Author: WSFLX
# Version: 1.0
# IMPORTANT: This script requires administrative privileges

$ErrorActionPreference = "Stop"

# Check for administrative privileges
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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

function Install-NerdFont {
    Write-ColorOutput "Installing Nerd Fonts..." "Yellow"

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

            # Use Start-Process to run winget with a timeout to avoid hanging
            $proc = Start-Process -FilePath "winget" -ArgumentList "install", "JanDeDobbeleer.OhMyPosh", "-e", "--accept-source-agreements", "--accept-package-agreements" -NoNewWindow -PassThru

            # Wait for the process with a timeout (1,5 minutes)
            $waitResult = $proc.WaitForExit(90000)

            if (-not $waitResult) {
                Write-ColorOutput "Winget installation is taking too long, attempting to terminate..." "Yellow"
                try {
                    $proc.Kill()
                } catch {
                    # Process might have exited between our check and kill attempt
                }

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
                }
            }
        } catch {
            Write-ColorOutput "Failed to install Oh My Posh using winget: $_" "Red"
            Write-ColorOutput "Trying alternative installation method..." "Yellow"
        }
    } else {
        Write-ColorOutput "Winget not found. Using direct installation method..." "Yellow"
    }

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

    # Create PowerShell profile directory if it doesn't exist
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # Create PowerShell profile if it doesn't exist
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    # Check if Oh My Posh is already configured in the profile
    $profileContent = Get-Content -Path $PROFILE -ErrorAction SilentlyContinue
    $ohMyPoshConfig = "oh-my-posh init pwsh --config `"`$env:POSH_THEMES_PATH\craver.omp.json`" | Invoke-Expression"

    if ($profileContent -match "oh-my-posh init pwsh") {
        Write-ColorOutput "Oh My Posh already configured in PowerShell profile." "Cyan"
    } else {
        # Add Oh My Posh configuration to the profile
        try {
            Add-Content -Path $PROFILE -Value "`n# Oh My Posh Theme`n$ohMyPoshConfig`n"
            Write-ColorOutput "Oh My Posh configured in PowerShell profile." "Green"
        } catch {
            Write-ColorOutput "Failed to update PowerShell profile: $_" "Red"
            return $false
        }
    }

    return $true
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

# Main script execution
try {
    Write-ColorOutput "Starting terminal styling script..." "Magenta"
    Write-ColorOutput "----------------------------------" "Magenta"

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
        $StatusTracker."Oh My Posh".Message = "Installed"
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

} catch {
    Write-ColorOutput "An error occurred: $_" "Red"
    Write-ColorOutput "Please try running the script again or manually complete the remaining steps." "Red"
    exit 1
}

