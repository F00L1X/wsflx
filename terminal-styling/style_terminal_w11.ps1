# Style Terminal for Windows (7-11)
# This script installs Oh My Posh and configures fonts for PowerShell, Windows Terminal, and VS Code
# Author: WSFLX
# Version: 1.0

$ErrorActionPreference = "Stop"

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
        # Get the latest release version from GitHub API
        Write-ColorOutput "Fetching latest Nerd Font release information..." "Yellow"
        $apiUrl = "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"

        # Use TLS 1.2 for older Windows versions
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $latestRelease = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        $latestVersion = $latestRelease.tag_name

        Write-ColorOutput "Found latest Nerd Font version: $latestVersion" "Green"
        $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/$latestVersion/Meslo.zip"
    }
    catch {
        Write-ColorOutput "Failed to fetch latest release, using fallback version: $_" "Yellow"
        # Fallback to a known version if API call fails
        $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip"
    }

    $tempFolder = Join-Path $env:TEMP "NerdFonts"
    $fontZip = Join-Path $tempFolder "Meslo.zip"

    # Create temp folder if it doesn't exist
    if (-not (Test-Path $tempFolder)) {
        New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null
    }

    # Download font
    try {
        Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip
        Write-ColorOutput "Font downloaded successfully." "Green"
    } catch {
        Write-ColorOutput "Failed to download font: $_" "Red"
        return $false
    }

    # Extract font
    try {
        Expand-Archive -Path $fontZip -DestinationPath $tempFolder -Force
        Write-ColorOutput "Font extracted successfully." "Green"
    } catch {
        Write-ColorOutput "Failed to extract font: $_" "Red"
        return $false
    }

    # Install font
    try {
        $fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
        foreach ($file in Get-ChildItem -Path $tempFolder -Recurse -Include "*.ttf", "*.otf") {
            $fileName = $file.Name
            if (Test-Path -Path "$env:WINDIR\Fonts\$fileName") {
                Write-ColorOutput "Font $fileName already installed." "Cyan"
            } else {
                $fonts.CopyHere($file.FullName)
                Write-ColorOutput "Font $fileName installed." "Green"
            }
        }
        return $true
    } catch {
        Write-ColorOutput "Failed to install font: $_" "Red"
        return $false
    } finally {
        # Clean up
        if (Test-Path $tempFolder) {
            Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
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
            winget install JanDeDobbeleer.OhMyPosh -e

            # Refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

            if (Test-CommandExists "oh-my-posh") {
                Write-ColorOutput "Oh My Posh installed successfully using winget." "Green"
                return $true
            }
        } catch {
            Write-ColorOutput "Failed to install Oh My Posh using winget: $_" "Red"
        }
    } else {
        Write-ColorOutput "Winget not found. Trying alternative installation method..." "Yellow"
    }

    # Alternative installation using direct installer
    try {
        Write-ColorOutput "Installing Oh My Posh using installer script..." "Yellow"

        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))

        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        if (Test-CommandExists "oh-my-posh") {
            Write-ColorOutput "Oh My Posh installed successfully using installer script." "Green"
            return $true
        } else {
            Write-ColorOutput "Failed to install Oh My Posh." "Red"
            return $false
        }
    } catch {
        Write-ColorOutput "Failed to install Oh My Posh: $_" "Red"
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
        "Nerd Font" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "Oh My Posh" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "PowerShell Profile" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "Windows Terminal" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "VS Code" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
        "Cursor" = @{ Status = $false; Message = "Not Started"; Color = "Red" }
    }

    # Step 1: Install Nerd Fonts
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

    # Step 2: Install Oh My Posh
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

