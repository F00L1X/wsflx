# GitHub Artifacts Manager
# A PowerShell script to manage GitHub artifacts with a dark-themed UI

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Define the XAML for the UI
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="GitHub Artifacts Manager" Height="600" Width="850" WindowStartupLocation="CenterScreen" Background="#1E1E1E">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#2D2D30" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="Margin" Value="5" />
            <Setter Property="Padding" Value="10,5" />
            <Setter Property="BorderBrush" Value="#3F3F46" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="3">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#3E3E42" />
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#007ACC" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#2D2D30" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="BorderBrush" Value="#3F3F46" />
            <Setter Property="Padding" Value="5" />
        </Style>
        <Style TargetType="PasswordBox">
            <Setter Property="Background" Value="#2D2D30" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="BorderBrush" Value="#3F3F46" />
            <Setter Property="Padding" Value="5" />
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#2D2D30" />
            <Setter Property="Foreground" Value="White" />
            <Setter Property="BorderBrush" Value="#3F3F46" />
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="White" />
        </Style>
        <Style TargetType="Label">
            <Setter Property="Foreground" Value="White" />
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="White" />
        </Style>
        <Style TargetType="ListView">
            <Setter Property="Background" Value="#252526" />
            <Setter Property="BorderBrush" Value="#3F3F46" />
            <Setter Property="Foreground" Value="White" />
        </Style>
        <Style TargetType="ProgressBar">
            <Setter Property="Background" Value="#3F3F46" />
            <Setter Property="Foreground" Value="#007ACC" />
            <Setter Property="Height" Value="10" />
        </Style>
    </Window.Resources>
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <!-- Title -->
        <TextBlock Grid.Row="0" FontSize="24" FontWeight="Bold" Margin="0,0,0,10">
            GitHub Artifacts Manager
        </TextBlock>

        <!-- Token Input -->
        <Grid Grid.Row="1" Margin="0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
            </Grid.ColumnDefinitions>
            <Label Grid.Column="0" Content="GitHub Personal Access Token:" VerticalAlignment="Center" />
            <PasswordBox Grid.Column="1" Name="PatPasswordBox" Margin="5,0,5,0" Height="30" VerticalContentAlignment="Center" />
            <Button Grid.Column="2" Name="ConnectButton" Content="Connect" Padding="10,5" />
        </Grid>

        <!-- Action Button -->
        <Grid Grid.Row="2" Margin="0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Name="ConnectionStatusTextBlock" VerticalAlignment="Center" />
            <Button Grid.Column="1" Name="ShowArtifactsButton" Content="Show All Artifacts" Padding="10,5" IsEnabled="False" />
        </Grid>

        <!-- Progress Section -->
        <Border Grid.Row="3" Margin="0,10" Padding="10" Background="#252526" BorderBrush="#3F3F46" BorderThickness="1" Visibility="Collapsed" Name="ProgressBorder">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" Name="ProgressTitleTextBlock" FontWeight="Bold" Margin="0,0,0,5">Search Progress</TextBlock>
                <ProgressBar Grid.Row="1" Name="ProgressBar" Margin="0,5" />
                <TextBlock Grid.Row="2" Name="ProgressTextBlock" Margin="0,5">Preparing search...</TextBlock>
                <TextBlock Grid.Row="3" Name="ProgressDetailTextBlock" Margin="0,5" TextWrapping="Wrap"></TextBlock>
            </Grid>
        </Border>

        <!-- Stats Section -->
        <Border Grid.Row="4" Margin="0,10" Padding="10" Background="#252526" BorderBrush="#3F3F46" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Name="ReposCountTextBlock">Repositories: 0</TextBlock>
                <TextBlock Grid.Column="1" Name="ArtifactsCountTextBlock">Artifacts: 0</TextBlock>
                <TextBlock Grid.Column="2" Name="SelectedArtifactsTextBlock">Selected: 0</TextBlock>
            </Grid>
        </Border>

        <!-- Artifacts List -->
        <ListView Grid.Row="5" Name="ArtifactsListView" Margin="0,10" SelectionMode="Multiple">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="ID" DisplayMemberBinding="{Binding id}" Width="60" />
                    <GridViewColumn Header="Name" DisplayMemberBinding="{Binding name}" Width="180" />
                    <GridViewColumn Header="Repository" DisplayMemberBinding="{Binding repository}" Width="180" />
                    <GridViewColumn Header="Size" DisplayMemberBinding="{Binding size_display}" Width="80" />
                    <GridViewColumn Header="Created At" DisplayMemberBinding="{Binding created_at_display}" Width="120" />
                    <GridViewColumn Header="Workflow" DisplayMemberBinding="{Binding workflow_name}" Width="150" />
                </GridView>
            </ListView.View>
        </ListView>

        <!-- Action Buttons -->
        <StackPanel Grid.Row="6" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
            <Button Name="DownloadButton" Content="Download Selected" Width="150" IsEnabled="False" />
            <Button Name="DeleteButton" Content="Delete Selected" Width="150" IsEnabled="False" Margin="10,0,0,0" />
        </StackPanel>

        <!-- Status Bar -->
        <Border Grid.Row="7" BorderBrush="#3F3F46" BorderThickness="0,1,0,0" Margin="0,10,0,0" Padding="0,5,0,0">
            <TextBlock Name="StatusTextBlock" Text="Ready" />
        </Border>
    </Grid>
</Window>
"@

# Create a window from the XAML
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Get UI elements
$patPasswordBox = $window.FindName('PatPasswordBox')
$connectButton = $window.FindName('ConnectButton')
$connectionStatusTextBlock = $window.FindName('ConnectionStatusTextBlock')
$showArtifactsButton = $window.FindName('ShowArtifactsButton')
$artifactsListView = $window.FindName('ArtifactsListView')
$downloadButton = $window.FindName('DownloadButton')
$deleteButton = $window.FindName('DeleteButton')
$statusTextBlock = $window.FindName('StatusTextBlock')

# Progress elements
$progressBorder = $window.FindName('ProgressBorder')
$progressBar = $window.FindName('ProgressBar')
$progressTextBlock = $window.FindName('ProgressTextBlock')
$progressDetailTextBlock = $window.FindName('ProgressDetailTextBlock')
$progressTitleTextBlock = $window.FindName('ProgressTitleTextBlock')

# Stats elements
$reposCountTextBlock = $window.FindName('ReposCountTextBlock')
$artifactsCountTextBlock = $window.FindName('ArtifactsCountTextBlock')
$selectedArtifactsTextBlock = $window.FindName('SelectedArtifactsTextBlock')

# Variables to store artifacts and selected artifacts
$global:allArtifacts = @()
$global:selectedArtifacts = @()
$global:isConnected = $false
$global:userName = ""
$global:validToken = ""
$global:searchLog = @()

# Function to update the UI thread
function Update-UIThread {
    param (
        [ScriptBlock]$Code
    )

    if ($window.Dispatcher.CheckAccess()) {
        & $Code
    }
    else {
        $window.Dispatcher.Invoke($Code)
    }
}

# Function to format file size
function Format-FileSize {
    param ([long]$Size)

    if ($Size -ge 1GB) {
        return "{0:N2} GB" -f ($Size / 1GB)
    }
    elseif ($Size -ge 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    }
    elseif ($Size -ge 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    }
    else {
        return "$Size bytes"
    }
}

# Function to validate GitHub Token
function Test-GitHubToken {
    param (
        [string]$Token
    )

    $connectionStatusTextBlock.Text = "Validating token..."

    try {
        # Set up headers with the token
        $headers = @{
            "Authorization" = "token $Token"
            "Accept" = "application/vnd.github.v3+json"
        }

        # Try to get user information to validate token
        $userUrl = "https://api.github.com/user"
        $response = Invoke-RestMethod -Uri $userUrl -Headers $headers -Method Get

        # Token is valid
        $global:isConnected = $true
        $global:userName = $response.login
        $global:validToken = $Token

        # Change connect button color to green
        $connectButton.Background = "#2EA043"

        $connectionStatusTextBlock.Text = "Connected as: $($response.login)"
        $showArtifactsButton.IsEnabled = $true

        return $true
    }
    catch {
        $global:isConnected = $false
        $connectButton.Background = "#2D2D30"
        $connectionStatusTextBlock.Text = "Token validation failed: $_"
        $showArtifactsButton.IsEnabled = $false

        return $false
    }
}

# Function to get all user repositories
function Get-UserRepos {
    param([string]$Token)

    Write-Host "`n[Repository Search] Starting repository search..." -ForegroundColor Cyan

    $headers = @{
        "Authorization" = "token $Token"
        "Accept" = "application/vnd.github.v3+json"
    }

    $allRepos = @()
    $page = 1
    $perPage = 100
    $hasMoreRepos = $true

    while ($hasMoreRepos) {
        $reposUrl = "https://api.github.com/user/repos?page=$page&per_page=$perPage"
        Write-Host "[API Request] GET $reposUrl" -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri $reposUrl -Headers $headers -Method Get

        $allRepos += $response
        Write-Host "[Repository Search] Found $($response.Count) repositories on page $page" -ForegroundColor Green

        if ($response.Count -lt $perPage) {
            $hasMoreRepos = $false
        }
        else {
            $page++
        }
    }

    Write-Host "[Repository Search] Total repositories found: $($allRepos.Count)" -ForegroundColor Cyan
    return $allRepos
}

# Function to get GitHub artifacts for all repositories
function Get-AllGitHubArtifacts {
    param (
        [string]$Token
    )

    # Initialize the UI
    Update-UIThread {
        $progressBorder.Visibility = "Visible"
        $progressBar.Value = 0
        $progressTitleTextBlock.Text = "Search Progress"
        $progressTextBlock.Text = "Preparing to fetch artifacts..."
        $progressDetailTextBlock.Text = ""
        $statusTextBlock.Text = "Fetching artifacts from all repositories..."
        $artifactsListView.ItemsSource = $null
    }

    # Create a runspace for background processing
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("Token", $Token)

    # Create a PowerShell command
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace

    # Add your script to the PowerShell command
    $script = {
        # Get all user repositories
        function Get-UserRepos {
            param([string]$Token)

            $headers = @{
                "Authorization" = "token $Token"
                "Accept" = "application/vnd.github.v3+json"
            }

            $allRepos = @()
            $page = 1
            $perPage = 100
            $hasMoreRepos = $true

            while ($hasMoreRepos) {
                $reposUrl = "https://api.github.com/user/repos?page=$page&per_page=$perPage"
                $response = Invoke-RestMethod -Uri $reposUrl -Headers $headers -Method Get

                $allRepos += $response

                if ($response.Count -lt $perPage) {
                    $hasMoreRepos = $false
                }
                else {
                    $page++
                }
            }

            return $allRepos
        }

        # Format file size
        function Format-Size {
            param ([long]$Size)

            if ($Size -ge 1GB) {
                return "{0:N2} GB" -f ($Size / 1GB)
            }
            elseif ($Size -ge 1MB) {
                return "{0:N2} MB" -f ($Size / 1MB)
            }
            elseif ($Size -ge 1KB) {
                return "{0:N2} KB" -f ($Size / 1KB)
            }
            else {
                return "$Size bytes"
            }
        }

        try {
            $repositories = Get-UserRepos -Token $Token
            $totalRepos = $repositories.Count
            $processedRepos = 0
            $reposWithArtifacts = 0
            $totalArtifactsFound = 0
            $allArtifacts = @()
            $searchLog = @()

            # Set up headers with the token
            $headers = @{
                "Authorization" = "token $Token"
                "Accept" = "application/vnd.github.v3+json"
            }

            foreach ($repo in $repositories) {
                $processedRepos++
                $owner = $repo.owner.login
                $repoName = $repo.name
                $repoFullName = "$owner/$repoName"
                Write-Host "`n[Scanning] Repository: $repoFullName ($processedRepos of $totalRepos)" -ForegroundColor Magenta
                $searchLog += "Scanning repository: $repoFullName"

                # Get artifacts directly for this repository
                $repoArtifactsFound = 0

                # First get workflow runs
                $runsUrl = "https://api.github.com/repos/$repoFullName/actions/runs"
                try {
                    Write-Host "[API Request] GET $runsUrl" -ForegroundColor Yellow
                    $runsResponse = Invoke-RestMethod -Uri $runsUrl -Headers $headers -Method Get

                    if ($runsResponse.total_count -gt 0) {
                        Write-Host "[Workflow Runs] Found $($runsResponse.total_count) workflow runs" -ForegroundColor Green
                        $searchLog += "  - Found $($runsResponse.total_count) workflow runs"

                        # Get artifacts for each workflow run
                        foreach ($run in $runsResponse.workflow_runs) {
                            $workflowName = $run.name
                            $runId = $run.id

                            $artifactsUrl = "https://api.github.com/repos/$repoFullName/actions/runs/$runId/artifacts"
                            Write-Host "[API Request] GET $artifactsUrl" -ForegroundColor Yellow
                            $artifactsResponse = Invoke-RestMethod -Uri $artifactsUrl -Headers $headers -Method Get

                            if ($artifactsResponse.total_count -gt 0) {
                                Write-Host "[Artifacts] Found $($artifactsResponse.total_count) artifacts in workflow '$workflowName'" -ForegroundColor Green
                                $searchLog += "    - Found $($artifactsResponse.total_count) artifacts in workflow '$workflowName'"

                                foreach ($artifact in $artifactsResponse.artifacts) {
                                    # Add repository and workflow information to artifact
                                    $artifact | Add-Member -NotePropertyName "repository" -NotePropertyValue $repoFullName -Force
                                    $artifact | Add-Member -NotePropertyName "workflow_name" -NotePropertyValue $workflowName -Force

                                    # Add formatted date and size
                                    $artifact | Add-Member -NotePropertyName "created_at_display" -NotePropertyValue ([DateTime]$artifact.created_at).ToString("yyyy-MM-dd HH:mm") -Force
                                    $artifact | Add-Member -NotePropertyName "size_display" -NotePropertyValue (Format-Size -Size $artifact.size_in_bytes) -Force

                                    $allArtifacts += $artifact
                                    $repoArtifactsFound++
                                    $totalArtifactsFound++
                                }
                            }
                        }
                    }

                    # Also check the repository artifacts
                    $repoArtifactsUrl = "https://api.github.com/repos/$repoFullName/actions/artifacts"
                    Write-Host "[API Request] GET $repoArtifactsUrl" -ForegroundColor Yellow
                    $repoArtifactsResponse = Invoke-RestMethod -Uri $repoArtifactsUrl -Headers $headers -Method Get

                    if ($repoArtifactsResponse.total_count -gt 0) {
                        Write-Host "[Artifacts] Found $($repoArtifactsResponse.total_count) additional artifacts" -ForegroundColor Green
                        $searchLog += "  - Found $($repoArtifactsResponse.total_count) additional artifacts"

                        foreach ($artifact in $repoArtifactsResponse.artifacts) {
                            # Skip artifacts we've already processed
                            if (-not ($allArtifacts | Where-Object { $_.id -eq $artifact.id })) {
                                # Add repository and workflow information
                                $artifact | Add-Member -NotePropertyName "repository" -NotePropertyValue $repoFullName -Force
                                $artifact | Add-Member -NotePropertyName "workflow_name" -NotePropertyValue "Unknown" -Force

                                # Add formatted date and size
                                $artifact | Add-Member -NotePropertyName "created_at_display" -NotePropertyValue ([DateTime]$artifact.created_at).ToString("yyyy-MM-dd HH:mm") -Force
                                $artifact | Add-Member -NotePropertyName "size_display" -NotePropertyValue (Format-Size -Size $artifact.size_in_bytes) -Force

                                $allArtifacts += $artifact
                                $repoArtifactsFound++
                                $totalArtifactsFound++
                            }
                        }
                    }

                    if ($repoArtifactsFound -gt 0) {
                        $reposWithArtifacts++
                        Write-Host "[Summary] Total artifacts found in $repoFullName`: $repoArtifactsFound" -ForegroundColor Cyan
                        $searchLog += "  - Total: $repoArtifactsFound artifacts found in $repoFullName"
                    }
                    else {
                        Write-Host "[Summary] No artifacts found in $repoFullName" -ForegroundColor Gray
                        $searchLog += "  - No artifacts found in $repoFullName"
                    }
                }
                catch {
                    Write-Host "[Error] Failed to access $repoFullName`: $_" -ForegroundColor Red
                    $searchLog += "  - Error accessing $($repoFullName): $_"
                    # Skip repositories that don't have workflows or where we don't have permission
                    continue
                }
            }

            # Return all the collected data
            return @{
                Success = $true
                AllArtifacts = $allArtifacts
                SearchLog = $searchLog
                ReposCount = $totalRepos
                ReposWithArtifactsCount = $reposWithArtifacts
                TotalArtifactsFound = $totalArtifactsFound
            }
        }
        catch {
            return @{
                Success = $false
                ErrorMessage = $_.Exception.Message
            }
        }
    }

    $powershell.AddScript($script) | Out-Null

    # Start the job asynchronously
    $handle = $powershell.BeginInvoke()

    # Monitor progress
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $active = $true

    while ($active) {
        if ($handle.IsCompleted) {
            $active = $false

            # Get the result
            try {
                $result = $powershell.EndInvoke($handle)

                if ($result.Success) {
                    # Update UI with the results
                    Update-UIThread {
                        $global:allArtifacts = $result.AllArtifacts
                        $global:searchLog = $result.SearchLog

                        $progressBar.Value = 100
                        $reposCountTextBlock.Text = "Repositories: $($result.ReposCount)"
                        $artifactsCountTextBlock.Text = "Artifacts: $($result.TotalArtifactsFound)"

                        # Update the ListView
                        $artifactsListView.ItemsSource = $global:allArtifacts

                        if ($result.TotalArtifactsFound -eq 0) {
                            $progressTextBlock.Text = "Search complete - No artifacts found"
                            $progressDetailTextBlock.Text = "Searched $($result.ReposCount) repositories"
                            $statusTextBlock.Text = "No artifacts found in any repository."
                        }
                        else {
                            $progressTextBlock.Text = "Search complete - Found $($result.TotalArtifactsFound) artifacts in $($result.ReposWithArtifactsCount) repositories"
                            $progressDetailTextBlock.Text = "Found artifacts in $($result.ReposWithArtifactsCount) out of $($result.ReposCount) repositories"
                            $statusTextBlock.Text = "Found $($result.TotalArtifactsFound) artifacts across $($result.ReposWithArtifactsCount) repositories."
                        }
                    }
                }
                else {
                    Update-UIThread {
                        $progressTextBlock.Text = "Error during search"
                        $progressDetailTextBlock.Text = "Error: $($result.ErrorMessage)"
                        $statusTextBlock.Text = "Error: $($result.ErrorMessage)"
                        [System.Windows.MessageBox]::Show("Error fetching artifacts: $($result.ErrorMessage)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                    }
                }
            }
            catch {
                Update-UIThread {
                    $progressTextBlock.Text = "Error processing results"
                    $progressDetailTextBlock.Text = "Error: $_"
                    $statusTextBlock.Text = "Error: $_"
                    [System.Windows.MessageBox]::Show("Error: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                }
            }
            finally {
                # Cleanup
                $powershell.Dispose()
                $runspace.Dispose()
            }
        }
        else {
            # Update progress while waiting
            $seconds = $timer.Elapsed.TotalSeconds
            $percentComplete = [Math]::Min(95, ($seconds / (10 + ($seconds / 10))) * 100)

            Update-UIThread {
                $progressBar.Value = $percentComplete

                if ($seconds -gt 5 -and $progressDetailTextBlock.Text -eq "") {
                    $progressDetailTextBlock.Text = "Searching repositories... This may take a few minutes."
                }
                elseif ($seconds -gt 30 -and -not $progressDetailTextBlock.Text.Contains("large number")) {
                    $progressDetailTextBlock.Text = "Searching repositories... This may take a while for accounts with a large number of repositories."
                }
            }

            Start-Sleep -Milliseconds 200
        }
    }
}

# Function to download selected artifacts
function Download-SelectedArtifacts {
    param (
        [string]$Token,
        [array]$Artifacts
    )

    Update-UIThread {
        $progressBorder.Visibility = "Visible"
        $progressBar.Value = 0
        $progressTitleTextBlock.Text = "Download Progress"
        $progressTextBlock.Text = "Preparing to download artifacts..."
        $progressDetailTextBlock.Text = ""
        $statusTextBlock.Text = "Downloading artifacts..."
    }

    # Create a runspace for background processing
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("Token", $Token)
    $runspace.SessionStateProxy.SetVariable("Artifacts", $Artifacts)
    $runspace.SessionStateProxy.SetVariable("DownloadFolder", (Join-Path -Path $env:USERPROFILE -ChildPath "Downloads\GitHubArtifacts"))

    # Create a PowerShell command
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace

    # Add your script to the PowerShell command
    $script = {
        try {
            $token = $Token
            $artifacts = $Artifacts
            $downloadFolder = $DownloadFolder

            # Set up headers with the token
            $headers = @{
                "Authorization" = "token $token"
                "Accept" = "application/vnd.github.v3+json"
            }

            # Create download folder
            if (-not (Test-Path -Path $downloadFolder)) {
                New-Item -Path $downloadFolder -ItemType Directory -Force | Out-Null
            }

            $totalArtifacts = $artifacts.Count
            $downloadedArtifacts = 0
            $artifactStatus = @{}

            foreach ($artifact in $artifacts) {
                $repoName = $artifact.repository -replace "/", "_"
                $artifactStatus[$artifact.id] = "Downloading: $($artifact.name) from $($artifact.repository)"

                # Create repo-specific folder
                $repoFolder = Join-Path -Path $downloadFolder -ChildPath $repoName
                if (-not (Test-Path -Path $repoFolder)) {
                    New-Item -Path $repoFolder -ItemType Directory -Force | Out-Null
                }

                $outputPath = Join-Path -Path $repoFolder -ChildPath "$($artifact.name).zip"

                # Download the artifact
                Invoke-WebRequest -Uri $artifact.archive_download_url -Headers $headers -OutFile $outputPath

                $downloadedArtifacts++
                $artifactStatus[$artifact.id] = "Downloaded: $($artifact.name) from $($artifact.repository)"
            }

            return @{
                Success = $true
                DownloadFolder = $downloadFolder
                TotalArtifacts = $totalArtifacts
                DownloadedArtifacts = $downloadedArtifacts
                ArtifactStatus = $artifactStatus
            }
        }
        catch {
            return @{
                Success = $false
                ErrorMessage = $_.Exception.Message
            }
        }
    }

    $powershell.AddScript($script) | Out-Null

    # Start the job asynchronously
    $handle = $powershell.BeginInvoke()

    # Monitor progress
    $active = $true
    $totalArtifacts = $Artifacts.Count
    $lastCheck = [DateTime]::Now

    while ($active) {
        if ($handle.IsCompleted) {
            $active = $false

            # Get the result
            try {
                $result = $powershell.EndInvoke($handle)

                if ($result.Success) {
                    # Update UI with the results
                    Update-UIThread {
                        $progressBar.Value = 100
                        $progressTextBlock.Text = "Download complete"
                        $progressDetailTextBlock.Text = "All $($result.TotalArtifacts) artifacts downloaded to: $($result.DownloadFolder)"
                        $statusTextBlock.Text = "All artifacts downloaded to: $($result.DownloadFolder)"
                        [System.Windows.MessageBox]::Show("All artifacts downloaded to: $($result.DownloadFolder)", "Download Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

                        # Hide the progress section after completion
                        $progressBorder.Visibility = "Collapsed"
                    }

                    # Open the folder
                    Start-Process -FilePath "explorer.exe" -ArgumentList $result.DownloadFolder
                }
                else {
                    Update-UIThread {
                        $progressTextBlock.Text = "Error during download"
                        $progressDetailTextBlock.Text = "Error: $($result.ErrorMessage)"
                        $statusTextBlock.Text = "Error: $($result.ErrorMessage)"
                        [System.Windows.MessageBox]::Show("Error downloading artifacts: $($result.ErrorMessage)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                    }
                }
            }
            catch {
                Update-UIThread {
                    $progressTextBlock.Text = "Error during download"
                    $progressDetailTextBlock.Text = "Error: $_"
                    $statusTextBlock.Text = "Error: $_"
                    [System.Windows.MessageBox]::Show("Error: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                }
            }
            finally {
                # Cleanup
                $powershell.Dispose()
                $runspace.Dispose()
            }
        }
        else {
            # Check status periodically
            if (([DateTime]::Now - $lastCheck).TotalMilliseconds -gt 500) {
                $lastCheck = [DateTime]::Now

                # Try to get status from runspace
                try {
                    $downloadedArtifacts = $runspace.SessionStateProxy.GetVariable("downloadedArtifacts")
                    $artifactStatus = $runspace.SessionStateProxy.GetVariable("artifactStatus")

                    if ($downloadedArtifacts -gt 0) {
                        $percentComplete = [Math]::Min(100, [Math]::Round(($downloadedArtifacts / $totalArtifacts) * 100))

                        Update-UIThread {
                            $progressBar.Value = $percentComplete
                            $progressTextBlock.Text = "Downloading $downloadedArtifacts of $totalArtifacts artifacts ($percentComplete%)"

                            # Show the most recent status
                            if ($artifactStatus -and $artifactStatus.Count -gt 0) {
                                $lastStatus = $artifactStatus.Values | Select-Object -Last 1
                                $progressDetailTextBlock.Text = $lastStatus
                            }
                        }
                    }
                }
                catch {
                    # Ignore errors reading from runspace
                }
            }

            Start-Sleep -Milliseconds 100
        }
    }
}

# Function to delete selected artifacts
function Delete-SelectedArtifacts {
    param (
        [string]$Token,
        [array]$Artifacts
    )

    Update-UIThread {
        $progressBorder.Visibility = "Visible"
        $progressBar.Value = 0
        $progressTitleTextBlock.Text = "Delete Progress"
        $progressTextBlock.Text = "Preparing to delete artifacts..."
        $progressDetailTextBlock.Text = ""
        $statusTextBlock.Text = "Deleting artifacts..."
    }

    # Create a runspace for background processing
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("Token", $Token)
    $runspace.SessionStateProxy.SetVariable("Artifacts", $Artifacts)

    # Create a PowerShell command
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace

    # Add your script to the PowerShell command
    $script = {
        try {
            $token = $Token
            $artifacts = $Artifacts

            # Set up headers with the token
            $headers = @{
                "Authorization" = "token $token"
                "Accept" = "application/vnd.github.v3+json"
            }

            $totalArtifacts = $artifacts.Count
            $deletedArtifacts = 0
            $artifactStatus = @{}

            foreach ($artifact in $artifacts) {
                # Split repository name
                $repoSplit = $artifact.repository -split '/'
                $owner = $repoSplit[0]
                $repo = $repoSplit[1]

                $artifactStatus[$artifact.id] = "Deleting: $($artifact.name) from $($artifact.repository)"

                # Delete URL
                $deleteUrl = "https://api.github.com/repos/$owner/$repo/actions/artifacts/$($artifact.id)"

                # Delete the artifact
                Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete

                $deletedArtifacts++
                $artifactStatus[$artifact.id] = "Deleted: $($artifact.name) from $($artifact.repository)"
            }

            return @{
                Success = $true
                TotalArtifacts = $totalArtifacts
                DeletedArtifacts = $deletedArtifacts
                ArtifactStatus = $artifactStatus
            }
        }
        catch {
            return @{
                Success = $false
                ErrorMessage = $_.Exception.Message
            }
        }
    }

    $powershell.AddScript($script) | Out-Null

    # Start the job asynchronously
    $handle = $powershell.BeginInvoke()

    # Monitor progress
    $active = $true
    $totalArtifacts = $Artifacts.Count
    $lastCheck = [DateTime]::Now

    while ($active) {
        if ($handle.IsCompleted) {
            $active = $false

            # Get the result
            try {
                $result = $powershell.EndInvoke($handle)

                if ($result.Success) {
                    # Update UI with the results
                    Update-UIThread {
                        $progressBar.Value = 100
                        $progressTextBlock.Text = "Delete complete"
                        $progressDetailTextBlock.Text = "All $($result.TotalArtifacts) artifacts deleted successfully"
                        $statusTextBlock.Text = "All selected artifacts deleted."
                        [System.Windows.MessageBox]::Show("All selected artifacts have been deleted.", "Deletion Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

                        # Hide the progress section after completion
                        $progressBorder.Visibility = "Collapsed"
                    }

                    # Refresh the artifacts list
                    Get-AllGitHubArtifacts -Token $global:validToken
                }
                else {
                    Update-UIThread {
                        $progressTextBlock.Text = "Error during deletion"
                        $progressDetailTextBlock.Text = "Error: $($result.ErrorMessage)"
                        $statusTextBlock.Text = "Error: $($result.ErrorMessage)"
                        [System.Windows.MessageBox]::Show("Error deleting artifacts: $($result.ErrorMessage)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                    }
                }
            }
            catch {
                Update-UIThread {
                    $progressTextBlock.Text = "Error during deletion"
                    $progressDetailTextBlock.Text = "Error: $_"
                    $statusTextBlock.Text = "Error: $_"
                    [System.Windows.MessageBox]::Show("Error: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                }
            }
            finally {
                # Cleanup
                $powershell.Dispose()
                $runspace.Dispose()
            }
        }
        else {
            # Check status periodically
            if (([DateTime]::Now - $lastCheck).TotalMilliseconds -gt 500) {
                $lastCheck = [DateTime]::Now

                # Try to get status from runspace
                try {
                    $deletedArtifacts = $runspace.SessionStateProxy.GetVariable("deletedArtifacts")
                    $artifactStatus = $runspace.SessionStateProxy.GetVariable("artifactStatus")

                    if ($deletedArtifacts -gt 0) {
                        $percentComplete = [Math]::Min(100, [Math]::Round(($deletedArtifacts / $totalArtifacts) * 100))

                        Update-UIThread {
                            $progressBar.Value = $percentComplete
                            $progressTextBlock.Text = "Deleting $deletedArtifacts of $totalArtifacts artifacts ($percentComplete%)"

                            # Show the most recent status
                            if ($artifactStatus -and $artifactStatus.Count -gt 0) {
                                $lastStatus = $artifactStatus.Values | Select-Object -Last 1
                                $progressDetailTextBlock.Text = $lastStatus
                            }
                        }
                    }
                }
                catch {
                    # Ignore errors reading from runspace
                }
            }

            Start-Sleep -Milliseconds 100
        }
    }
}

# Event: Connect Button Click
$connectButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($patPasswordBox.Password)) {
        [System.Windows.MessageBox]::Show("Please enter a GitHub Personal Access Token.", "Missing Token", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Test-GitHubToken -Token $patPasswordBox.Password
})

# Event: Show Artifacts Button Click
$showArtifactsButton.Add_Click({
    if (-not $global:isConnected) {
        [System.Windows.MessageBox]::Show("Please connect with a valid GitHub token first.", "Not Connected", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    # Disable the button during search to prevent multiple clicks
    $showArtifactsButton.IsEnabled = $false

    # Clear current artifacts
    $global:allArtifacts = @()
    $artifactsListView.ItemsSource = $null
    $artifactsCountTextBlock.Text = "Artifacts: 0"
    $selectedArtifactsTextBlock.Text = "Selected: 0"
    $reposCountTextBlock.Text = "Repositories: 0"

    # Run the search
    Get-AllGitHubArtifacts -Token $global:validToken

    # Re-enable the button after search
    $showArtifactsButton.IsEnabled = $true
})

# Event: Selection Changed in ListView
$artifactsListView.Add_SelectionChanged({
    $global:selectedArtifacts = $artifactsListView.SelectedItems
    $downloadButton.IsEnabled = ($global:selectedArtifacts.Count -gt 0)
    $deleteButton.IsEnabled = ($global:selectedArtifacts.Count -gt 0)

    Update-UIThread {
        $selectedArtifactsTextBlock.Text = "Selected: $($global:selectedArtifacts.Count)"
    }

    if ($global:selectedArtifacts.Count -gt 0) {
        $statusTextBlock.Text = "$($global:selectedArtifacts.Count) artifacts selected."
    }
    else {
        $statusTextBlock.Text = "Ready"
    }
})

# Event: Download Button Click
$downloadButton.Add_Click({
    if ($global:selectedArtifacts.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Please select at least one artifact to download.", "No Selection", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $result = [System.Windows.MessageBox]::Show("You are about to download $($global:selectedArtifacts.Count) artifacts. Continue?", "Confirm Download", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)

    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        # Disable buttons during operation
        $downloadButton.IsEnabled = $false
        $deleteButton.IsEnabled = $false
        $showArtifactsButton.IsEnabled = $false

        Download-SelectedArtifacts -Token $global:validToken -Artifacts $global:selectedArtifacts

        # Re-enable buttons after operation
        $downloadButton.IsEnabled = ($global:selectedArtifacts.Count -gt 0)
        $deleteButton.IsEnabled = ($global:selectedArtifacts.Count -gt 0)
        $showArtifactsButton.IsEnabled = $true
    }
})

# Event: Delete Button Click
$deleteButton.Add_Click({
    if ($global:selectedArtifacts.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Please select at least one artifact to delete.", "No Selection", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $result = [System.Windows.MessageBox]::Show("WARNING: You are about to delete $($global:selectedArtifacts.Count) artifacts. This action cannot be undone. Continue?", "Confirm Deletion", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)

    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        # Disable buttons during operation
        $downloadButton.IsEnabled = $false
        $deleteButton.IsEnabled = $false
        $showArtifactsButton.IsEnabled = $false

        Delete-SelectedArtifacts -Token $global:validToken -Artifacts $global:selectedArtifacts

        # Buttons will be re-enabled after the refresh
    }
})

# Show the window
$window.ShowDialog() | Out-Null
