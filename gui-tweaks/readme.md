# Windows 11 UI Tweaks

A specialized PowerShell script designed to customize the Windows 11 user interface for improved usability and appearance.

## Features

- **Classic Context Menu**: Restore the more functional Windows 10-style context menu
- **Explorer Ribbon Menu**: Get back the classic File Explorer ribbon interface
- **Taskbar Customization**:
  - Show small icons in taskbar
  - Show titles in taskbar
  - Show all tray icons
  - Hide search box/button
  - Hide Task View button
- **Explorer Enhancements**:
  - Show file extensions
  - Show hidden files
  - Change default explorer view to "Computer"
- **Error Handling**: Robust error handling with visual feedback
- **Explorer Auto-Restart**: Safely restarts Explorer to apply changes

## Usage

### Prerequisites

- Windows 11
- PowerShell 5.1 or higher
- Administrator privileges

### Installation

#### Option 1: Direct download and run (recommended)

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/F00L1X/wsflx/main/gui-tweaks/tweakW11.ps1" -OutFile "$env:TEMP\tweakW11.ps1";Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:TEMP\tweakW11.ps1"
```

#### Option 2: Clone repository and run locally

```powershell
git clone https://github.com/F00L1X/wsflx.git
cd wsflx/gui-tweaks
Set-ExecutionPolicy Bypass -Scope Process -Force
.\tweakW11.ps1
```

## How It Works

1. **Launch the script** with administrator privileges
2. **Apply UI tweaks** automatically
3. **Prompt for Explorer restart** to apply changes immediately
4. **Enjoy a more user-friendly Windows 11 interface**

## Screenshots

### Before & After: Context Menu
*Images showing the default Windows 11 context menu vs the classic menu*
`Comming soon`

### Before & After: File Explorer
*Images showing the redesigned Windows 11 explorer vs the classic explorer*
`Comming soon`

## Windows Debloating

This script focuses solely on UI customization. For removing bloatware and enhancing privacy, use our companion script [debloatW11.ps1](../debloat/debloatW11.ps1).

## Caution

- Always create a system restore point before running
- Some changes may not be easily reversible
- Explorer will need to be restarted to apply changes

## Frequently Asked Questions

### Will this affect my Windows updates?

No, these UI tweaks don't interfere with the Windows Update mechanism.

### Can I undo these changes?

Yes, most changes can be reverted manually through registry edits or by running specialized commands.

### Why separate UI tweaks from debloating?

To provide more flexibility and focus. This script focuses on visual and usability enhancements, while the debloat script focuses on removing unnecessary components and enhancing privacy.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.