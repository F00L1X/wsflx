
# CSV Duplicate Remover

A powerful PowerShell tool to remove duplicate rows from CSV files with encoding fix support for German umlauts and special characters.

## 📸 Screenshot

![CSV Duplicate Remover GUI](GUI.png)
*User-friendly interface with file browser, encoding options, and real-time progress log*

## 🚀 Quick Start

### Option 1: Download and run (recommended)
Downloads and runs the script directly without cloning the entire repository:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/F00L1X/wsflx/main/excel/RemoveDuplicates.ps1" -OutFile "$env:TEMP\RemoveDuplicates.ps1";Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:TEMP\RemoveDuplicates.ps1" -GUI
```

**What this does:**
1. Downloads the script from GitHub to your temporary folder
2. Temporarily bypasses PowerShell execution policy for this session
3. Launches the GUI interface

### Option 2: Clone and run locally
Clones the entire repository to your machine for offline access and easier updates:
```powershell
git clone https://github.com/F00L1X/wsflx.git; cd wsflx/excel; Set-ExecutionPolicy Bypass -Scope Process -Force; .\RemoveDuplicates.ps1 -GUI
```

**What this does:**
1. Clones the entire wsflx repository to your current directory
2. Navigates to the excel folder
3. Temporarily bypasses PowerShell execution policy
4. Runs the script in GUI mode

**Benefits of cloning:**
- Access to all scripts in the repository
- Easy to update with `git pull`
- Can create shortcuts and customize locally
- No internet required after initial clone

### Option 3: Local shortcut (if already cloned)

**Easiest method after cloning:** Double-click the `CSV Duplicate Remover.lnk` shortcut

Or simply double-click `RemoveDuplicates-GUI.ps1` in Windows Explorer.

## Features

- **GUI Interface**: User-friendly Windows Forms interface with file browser
- **Encoding Fix**: Automatically fixes German umlaut encoding issues (Ã¤→ä, Ã¼→ü, etc.)
- **Duplicate Removal**: Removes duplicate rows by comparing ALL columns
- **Configurable Options**:
  - Fix umlaut encoding (checkbox)
  - Remove quotes from output (checkbox)
  - Custom delimiter (default: semicolon)
- **Real-time Progress Log**: See what's happening during processing
- **Preserves Data**: Works on semicolon-delimited CSV files
- **UTF-8 Output**: Proper encoding for international characters

### Command Line Mode

```powershell
# Basic usage with all features
.\RemoveDuplicates.ps1 -InputFile "input.csv" -OutputFile "output.csv" -FixUmlautEncoding -NoQuotes

# Custom delimiter (comma instead of semicolon)
.\RemoveDuplicates.ps1 -InputFile "input.csv" -OutputFile "output.csv" -Delimiter "," -FixUmlautEncoding
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-InputFile` | Path to input CSV file | Required in CLI mode |
| `-OutputFile` | Path to output CSV file | Required in CLI mode |
| `-FixUmlautEncoding` | Fix encoding issues (e.g., Ã¤ → ä) | `false` |
| `-NoQuotes` | Remove quotes from output CSV | `false` |
| `-Delimiter` | CSV delimiter character | `;` (semicolon) |
| `-GUI` | Launch GUI mode | Automatic if no params |

## What It Does

1. Loads CSV file with proper encoding handling
2. Optionally fixes umlaut/special character encoding issues
3. Removes duplicate rows (considers ALL fields)
4. Sorts data by EEID column
5. Exports clean CSV without quotes (optional)
6. Shows statistics (original rows, unique rows, duplicates removed)

## Example Output

```
Starting duplicate removal process...
Input file: C:\data\employees.csv
Output file: C:\data\employees_noDups.csv
Fix umlaut encoding: True

Loading CSV file...
Using delimiter: ';'
Original row count: 272

Removing duplicates...
Unique row count: 218
Duplicates removed: 54

Sorting data by EEID...
Exporting to new CSV file...

COMPLETE!
Summary:
  - Original rows: 272
  - Unique rows: 218
  - Duplicates removed: 54
  - Output file: C:\data\employees_noDups.csv

Process completed successfully!
```

## Notes

- The script creates a NEW file, so your original data remains untouched
- Duplicates are identified by comparing ALL columns in the CSV
- The output is automatically sorted by the EEID column (if present)
- Supports custom delimiters (comma, semicolon, tab, etc.)
- UTF-8 encoding ensures proper handling of international characters

## Files in this Folder

- `RemoveDuplicates.ps1` - Main script with GUI and CLI modes
- `RemoveDuplicates-GUI.ps1` - Launcher script that opens GUI mode directly
- `create_shortcut.ps1` - Creates desktop shortcut for easy access
- `CSV Duplicate Remover.lnk` - Desktop shortcut (created by create_shortcut.ps1)
- `readme.md` - This documentation file