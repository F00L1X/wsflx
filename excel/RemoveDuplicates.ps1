# PowerShell script to remove duplicate rows from CSV and sort the output
param(
    [string]$InputFile,
    [string]$OutputFile,
    [switch]$FixUmlautEncoding,
    [switch]$GUI,
    [string]$Delimiter = ';',
    [switch]$NoQuotes
)

# Load Windows Forms assembly for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to fix umlaut encoding issues
function Fix-UmlautEncoding {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    # Fix double-encoded UTF-8 characters
    # These are the byte patterns when UTF-8 is misinterpreted as Windows-1252
    # We use explicit string concatenation of character codes

    $result = $Text

    # ä (U+00E4): C3 A4 in UTF-8, shown as Ã¤ when misread as Win-1252
    $result = $result.Replace("$([char]0xC3)$([char]0xA4)", "$([char]0xE4)")

    # ö (U+00F6): C3 B6
    $result = $result.Replace("$([char]0xC3)$([char]0xB6)", "$([char]0xF6)")

    # ü (U+00FC): C3 BC
    $result = $result.Replace("$([char]0xC3)$([char]0xBC)", "$([char]0xFC)")

    # Ä (U+00C4): C3 84
    $result = $result.Replace("$([char]0xC3)$([char]0x84)", "$([char]0xC4)")

    # Ö (U+00D6): C3 96
    $result = $result.Replace("$([char]0xC3)$([char]0x96)", "$([char]0xD6)")

    # Ü (U+00DC): C3 9C
    $result = $result.Replace("$([char]0xC3)$([char]0x9C)", "$([char]0xDC)")

    # ß (U+00DF): C3 9F (normal double-encoding)
    $result = $result.Replace("$([char]0xC3)$([char]0x9F)", "$([char]0xDF)")

    # ÃŸ special case: U+00C3 U+0178 (misencoded ß)
    # This appears as "ÃŸ" in the file (Ã = U+00C3, Ÿ = U+0178)
    $result = $result.Replace("$([char]0xC3)$([char]0x0178)", "$([char]0xDF)")

    # é (U+00E9): C3 A9
    $result = $result.Replace("$([char]0xC3)$([char]0xA9)", "$([char]0xE9)")

    # è (U+00E8): C3 A8
    $result = $result.Replace("$([char]0xC3)$([char]0xA8)", "$([char]0xE8)")

    # à (U+00E0): C3 A0
    $result = $result.Replace("$([char]0xC3)$([char]0xA0)", "$([char]0xE0)")

    # â (U+00E2): C3 A2
    $result = $result.Replace("$([char]0xC3)$([char]0xA2)", "$([char]0xE2)")

    # î (U+00EE): C3 AE
    $result = $result.Replace("$([char]0xC3)$([char]0xAE)", "$([char]0xEE)")

    # ô (U+00F4): C3 B4
    $result = $result.Replace("$([char]0xC3)$([char]0xB4)", "$([char]0xF4)")

    # û (U+00FB): C3 BB
    $result = $result.Replace("$([char]0xC3)$([char]0xBB)", "$([char]0xFB)")

    # ç (U+00E7): C3 A7
    $result = $result.Replace("$([char]0xC3)$([char]0xA7)", "$([char]0xE7)")

    return $result
}

# Function to process CSV files
function Process-CSVFile {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [bool]$FixEncoding,
        [string]$CsvDelimiter = ';',
        [bool]$RemoveQuotes = $false,
        [System.Windows.Forms.TextBox]$LogBox = $null
    )

    function Write-Log {
        param([string]$Message, [string]$Color = "Black")
        if ($LogBox) {
            $LogBox.AppendText("$Message`r`n")
            $LogBox.Select($LogBox.Text.Length, 0)
            $LogBox.ScrollToCaret()
            [System.Windows.Forms.Application]::DoEvents()
        }
        else {
            Write-Host $Message -ForegroundColor $(if ($Color -eq "Black") { "White" } else { $Color })
        }
    }

    try {
        Write-Log "Starting duplicate removal process..." "Cyan"
        Write-Log "Input file: $InputPath"
        Write-Log "Output file: $OutputPath"
        Write-Log "Fix umlaut encoding: $FixEncoding"
        Write-Log ""

        # Check if input file exists
        if (-not (Test-Path $InputPath)) {
            Write-Log "ERROR: Input file not found: $InputPath" "Red"
            return $false
        }

        # Fix umlaut encoding if requested - must be done BEFORE parsing CSV
        if ($FixEncoding) {
            Write-Log "Fixing umlaut encoding issues in raw file..." "Yellow"

            # Read file as UTF-8 (the file is already UTF-8, but contains misencoded characters)
            $rawText = [System.IO.File]::ReadAllText($InputPath, [System.Text.UTF8Encoding]::new($false))

            # Apply encoding fixes
            $rawText = Fix-UmlautEncoding -Text $rawText

            # Create a temporary file with fixed encoding
            $tempFile = [System.IO.Path]::GetTempFileName()
            [System.IO.File]::WriteAllText($tempFile, $rawText, [System.Text.UTF8Encoding]::new($false))

            Write-Log "Umlaut encoding fixed! Using temp file for import." "Green"
            $fileToImport = $tempFile
        }
        else {
            $fileToImport = $InputPath
        }

        # Import the CSV file
        Write-Log "Loading CSV file..." "Yellow"
        Write-Log "Using delimiter: '$CsvDelimiter'"
        $csvData = Import-Csv -Path $fileToImport -Delimiter $CsvDelimiter -Encoding UTF8

        # Clean up temp file if it was created
        if ($FixEncoding -and (Test-Path $tempFile)) {
            Remove-Item $tempFile -Force
        }

        $originalCount = $csvData.Count
        Write-Log "Original row count: $originalCount"

        # Remove duplicates by comparing all properties
        Write-Log "Removing duplicates..." "Yellow"
        $uniqueData = $csvData | Sort-Object -Property * -Unique

        $uniqueCount = $uniqueData.Count
        $duplicatesRemoved = $originalCount - $uniqueCount

        Write-Log "Unique row count: $uniqueCount"
        Write-Log "Duplicates removed: $duplicatesRemoved" "Green"

        # Sort the data (by EEID as primary sort, you can modify this)
        Write-Log "Sorting data by EEID..." "Yellow"
        $sortedData = $uniqueData | Sort-Object -Property EEID

        # Export to new CSV file
        Write-Log "Exporting to new CSV file..." "Yellow"

        if ($RemoveQuotes) {
            Write-Log "Removing quotes from output..." "Yellow"
            # Get column names
            $properties = $sortedData[0].PSObject.Properties.Name

            # Build header line
            $headerLine = $properties -join $CsvDelimiter

            # Build data lines
            $dataLines = $sortedData | ForEach-Object {
                $row = $_
                $values = $properties | ForEach-Object {
                    $value = $row.$_
                    if ($null -eq $value) { "" } else { $value }
                }
                $values -join $CsvDelimiter
            }

            # Write to file
            $allLines = @($headerLine) + $dataLines
            [System.IO.File]::WriteAllLines($OutputPath, $allLines, [System.Text.UTF8Encoding]::new($false))
        }
        else {
            $sortedData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8 -Delimiter $CsvDelimiter
        }

        Write-Log ""
        Write-Log "COMPLETE!" "Green"
        Write-Log "Summary:" "Cyan"
        Write-Log "  - Original rows: $originalCount"
        Write-Log "  - Unique rows: $uniqueCount"
        Write-Log "  - Duplicates removed: $duplicatesRemoved"
        Write-Log "  - Output file: $OutputPath"
        Write-Log ""
        Write-Log "Process completed successfully!" "Green"

        return $true
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)" "Red"
        return $false
    }
}

# GUI Mode
if ($GUI -or (-not $InputFile -and -not $OutputFile)) {
    # Create the form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "CSV Duplicate Remover"
    $form.Size = New-Object System.Drawing.Size(600, 550)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    # Input file label
    $labelInput = New-Object System.Windows.Forms.Label
    $labelInput.Location = New-Object System.Drawing.Point(10, 20)
    $labelInput.Size = New-Object System.Drawing.Size(100, 20)
    $labelInput.Text = "Input CSV File:"
    $form.Controls.Add($labelInput)

    # Input file textbox
    $textBoxInput = New-Object System.Windows.Forms.TextBox
    $textBoxInput.Location = New-Object System.Drawing.Point(10, 45)
    $textBoxInput.Size = New-Object System.Drawing.Size(470, 20)
    $form.Controls.Add($textBoxInput)

    # Input file browse button
    $buttonBrowseInput = New-Object System.Windows.Forms.Button
    $buttonBrowseInput.Location = New-Object System.Drawing.Point(490, 43)
    $buttonBrowseInput.Size = New-Object System.Drawing.Size(80, 25)
    $buttonBrowseInput.Text = "Browse..."
    $buttonBrowseInput.Add_Click({
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
            $openFileDialog.Title = "Select Input CSV File"
            if ($openFileDialog.ShowDialog() -eq "OK") {
                $textBoxInput.Text = $openFileDialog.FileName
                # Auto-generate output filename
                $inputPath = $openFileDialog.FileName
                $directory = [System.IO.Path]::GetDirectoryName($inputPath)
                $filename = [System.IO.Path]::GetFileNameWithoutExtension($inputPath)
                $extension = [System.IO.Path]::GetExtension($inputPath)
                $textBoxOutput.Text = Join-Path $directory "$($filename)_noDups$extension"
            }
        })
    $form.Controls.Add($buttonBrowseInput)

    # Output file label
    $labelOutput = New-Object System.Windows.Forms.Label
    $labelOutput.Location = New-Object System.Drawing.Point(10, 80)
    $labelOutput.Size = New-Object System.Drawing.Size(100, 20)
    $labelOutput.Text = "Output CSV File:"
    $form.Controls.Add($labelOutput)

    # Output file textbox
    $textBoxOutput = New-Object System.Windows.Forms.TextBox
    $textBoxOutput.Location = New-Object System.Drawing.Point(10, 105)
    $textBoxOutput.Size = New-Object System.Drawing.Size(470, 20)
    $form.Controls.Add($textBoxOutput)

    # Output file browse button
    $buttonBrowseOutput = New-Object System.Windows.Forms.Button
    $buttonBrowseOutput.Location = New-Object System.Drawing.Point(490, 103)
    $buttonBrowseOutput.Size = New-Object System.Drawing.Size(80, 25)
    $buttonBrowseOutput.Text = "Browse..."
    $buttonBrowseOutput.Add_Click({
            $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveFileDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
            $saveFileDialog.Title = "Select Output CSV File"
            if ($saveFileDialog.ShowDialog() -eq "OK") {
                $textBoxOutput.Text = $saveFileDialog.FileName
            }
        })
    $form.Controls.Add($buttonBrowseOutput)

    # Fix umlaut encoding checkbox
    $checkBoxFixEncoding = New-Object System.Windows.Forms.CheckBox
    $checkBoxFixEncoding.Location = New-Object System.Drawing.Point(10, 140)
    $checkBoxFixEncoding.Size = New-Object System.Drawing.Size(400, 20)
    $checkBoxFixEncoding.Text = "Fix umlaut encoding issues (e.g., convert Ã¼ to ü)"
    $checkBoxFixEncoding.Checked = $false
    $form.Controls.Add($checkBoxFixEncoding)

    # Delimiter label
    $labelDelimiter = New-Object System.Windows.Forms.Label
    $labelDelimiter.Location = New-Object System.Drawing.Point(420, 140)
    $labelDelimiter.Size = New-Object System.Drawing.Size(60, 20)
    $labelDelimiter.Text = "Delimiter:"
    $form.Controls.Add($labelDelimiter)

    # Delimiter textbox
    $textBoxDelimiter = New-Object System.Windows.Forms.TextBox
    $textBoxDelimiter.Location = New-Object System.Drawing.Point(485, 138)
    $textBoxDelimiter.Size = New-Object System.Drawing.Size(30, 20)
    $textBoxDelimiter.Text = ";"
    $textBoxDelimiter.MaxLength = 1
    $form.Controls.Add($textBoxDelimiter)

    # Remove quotes checkbox
    $checkBoxNoQuotes = New-Object System.Windows.Forms.CheckBox
    $checkBoxNoQuotes.Location = New-Object System.Drawing.Point(525, 140)
    $checkBoxNoQuotes.Size = New-Object System.Drawing.Size(100, 20)
    $checkBoxNoQuotes.Text = "No Quotes"
    $checkBoxNoQuotes.Checked = $true
    $form.Controls.Add($checkBoxNoQuotes)

    # Process button
    $buttonProcess = New-Object System.Windows.Forms.Button
    $buttonProcess.Location = New-Object System.Drawing.Point(10, 170)
    $buttonProcess.Size = New-Object System.Drawing.Size(560, 35)
    $buttonProcess.Text = "Process CSV File"
    $buttonProcess.BackColor = [System.Drawing.Color]::LightGreen
    $buttonProcess.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $buttonProcess.Add_Click({
            if ([string]::IsNullOrWhiteSpace($textBoxInput.Text)) {
                [System.Windows.Forms.MessageBox]::Show("Please select an input file.", "Error", "OK", "Error")
                return
            }
            if ([string]::IsNullOrWhiteSpace($textBoxOutput.Text)) {
                [System.Windows.Forms.MessageBox]::Show("Please select an output file.", "Error", "OK", "Error")
                return
            }

            $buttonProcess.Enabled = $false
            $textBoxLog.Clear()

            $delimiterToUse = if ([string]::IsNullOrWhiteSpace($textBoxDelimiter.Text)) { ';' } else { $textBoxDelimiter.Text }
            $result = Process-CSVFile -InputPath $textBoxInput.Text -OutputPath $textBoxOutput.Text -FixEncoding $checkBoxFixEncoding.Checked -CsvDelimiter $delimiterToUse -RemoveQuotes $checkBoxNoQuotes.Checked -LogBox $textBoxLog

            $buttonProcess.Enabled = $true

            if ($result) {
                [System.Windows.Forms.MessageBox]::Show("CSV processing completed successfully!", "Success", "OK", "Information")
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("CSV processing failed. Check the log for details.", "Error", "OK", "Error")
            }
        })
    $form.Controls.Add($buttonProcess)

    # Log label
    $labelLog = New-Object System.Windows.Forms.Label
    $labelLog.Location = New-Object System.Drawing.Point(10, 215)
    $labelLog.Size = New-Object System.Drawing.Size(100, 20)
    $labelLog.Text = "Process Log:"
    $form.Controls.Add($labelLog)

    # Log textbox
    $textBoxLog = New-Object System.Windows.Forms.TextBox
    $textBoxLog.Location = New-Object System.Drawing.Point(10, 240)
    $textBoxLog.Size = New-Object System.Drawing.Size(560, 250)
    $textBoxLog.Multiline = $true
    $textBoxLog.ScrollBars = "Vertical"
    $textBoxLog.ReadOnly = $true
    $textBoxLog.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($textBoxLog)

    # Show the form
    [void]$form.ShowDialog()
    exit
}

# Command-line mode
if (-not [string]::IsNullOrWhiteSpace($InputFile) -and -not [string]::IsNullOrWhiteSpace($OutputFile)) {
    $result = Process-CSVFile -InputPath $InputFile -OutputPath $OutputFile -FixEncoding $FixUmlautEncoding -CsvDelimiter $Delimiter -RemoveQuotes $NoQuotes
    if (-not $result) {
        exit 1
    }
}
else {
    Write-Host "ERROR: Both InputFile and OutputFile parameters are required for command-line mode." -ForegroundColor Red
    Write-Host "For GUI mode, run the script without parameters or with -GUI flag." -ForegroundColor Yellow
    exit 1
}
