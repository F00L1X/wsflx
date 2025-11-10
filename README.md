# 🚀 wsflx
Windows Scripts by FLX

[![GitHub stars](https://img.shields.io/github/stars/F00L1X/wsflx?style=social)](https://github.com/F00L1X/wsflx/stargazers)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Platform-Windows%207--11-brightgreen)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A collection of PowerShell scripts to set up, maintain, clean, and optimize Windows operating systems.

## 📋 Table of Contents
- [Available Scripts](#available-scripts)
  - [🎨 Terminal Styling for Windows](#-terminal-styling-for-windows)
  - [🧹 Windows 11 Debloat Script](#-windows-11-debloat-script)
  - [🖌️ Windows 11 UI Tweaks](#-windows-11-ui-tweaks)
  - [🗑️ GitHub Artifacts Manager](#-github-artifacts-manager)
  - [🔄 Git Reset Helper](#-git-reset-helper)
  - [📊 CSV Duplicate Remover](#-csv-duplicate-remover)
- [Coming Soon](#-coming-soon)
- [Contributions](#-contributions)
- [License](#-license)

## 🔧 Available Scripts

### 🎨 Terminal Styling for Windows

Automatically style your terminal environment for Windows with Oh My Posh, custom fonts, and configuration for popular terminals and IDEs.

#### 🚀 Quick Start

##### Option 1: Download and run (recommended)
Copy & paste it to your admin terminal:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/F00L1X/wsflx/main/terminal-styling/style_terminal_w11.ps1" -OutFile "$env:TEMP\style_terminal_w11.ps1";Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:TEMP\style_terminal_w11.ps1"
```

##### Option 2: Clone and run locally
Copy & paste it to your admin terminal:
```powershell
git clone https://github.com/F00L1X/wsflx.git; cd wsflx/terminal-styling; Set-ExecutionPolicy Bypass -Scope Process -Force; .\style_terminal_w11.ps1
```

[📚 Learn more about Terminal Styling](terminal-styling/readme.md)

### 🧹 Windows 11 Debloat Script

Remove unnecessary bloatware, disable telemetry, and enhance privacy in Windows 11.

#### 🚀 Quick Start

##### Option 1: Download and run (recommended)
Copy & paste it to your admin terminal:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/F00L1X/wsflx/main/debloat/debloatW11.ps1" -OutFile "$env:TEMP\debloatW11.ps1";Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:TEMP\debloatW11.ps1"
```

##### Option 2: Clone and run locally
Copy & paste it to your admin terminal:
```powershell
git clone https://github.com/F00L1X/wsflx.git; cd wsflx/debloat; Set-ExecutionPolicy Bypass -Scope Process -Force; .\debloatW11.ps1
```

[📚 Learn more about Windows 11 Debloat](debloat/readme.md)

### 🖌️ Windows 11 UI Tweaks

Customize the Windows 11 UI with a more efficient and user-friendly interface, including the classic context menu.

#### 🚀 Quick Start

##### Option 1: Download and run (recommended)
Copy & paste it to your admin terminal:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/F00L1X/wsflx/main/ui-tweaks/set-tweakW11.ps1" -OutFile "$env:TEMP\set-tweakW11.ps1";Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:TEMP\set-tweakW11.ps1"
```

##### Option 2: Clone and run locally
Copy & paste it to your admin terminal:
```powershell
git clone https://github.com/F00L1X/wsflx.git; cd wsflx/ui-tweaks; Set-ExecutionPolicy Bypass -Scope Process -Force; .\set-tweakW11.ps1
```

[📚 Learn more about Windows 11 UI Tweaks](ui-tweaks/readme.md)

### 🗑️ GitHub Artifacts Manager

Manage GitHub workflow artifacts with a modern dark-themed UI. Download or delete artifacts across all your repositories with ease.

#### 🚀 Quick Start

##### Option 1: Download and run (recommended)
Copy & paste it to your admin terminal:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/F00L1X/wsflx/main/git/manage-git-artifacts.ps1" -OutFile "$env:TEMP\manage-git-artifacts.ps1";Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:TEMP\manage-git-artifacts.ps1"
```

##### Option 2: Clone and run locally
Copy & paste it to your admin terminal:
```powershell
git clone https://github.com/F00L1X/wsflx.git; cd wsflx/git; Set-ExecutionPolicy Bypass -Scope Process -Force; .\manage-git-artifacts.ps1
```

[📚 Learn more about GitHub Artifacts Manager](git/readme.md)

### 🔄 Git Reset Helper

An interactive Node.js CLI tool that simplifies resetting Git branches to specific commits with a user-friendly interface.

#### 🚀 Quick Start

##### Option 1: Download and run (recommended)
Copy & paste it to your terminal:
```bash
curl -o git-reset-helper.js https://raw.githubusercontent.com/F00L1X/wsflx/main/git/git-reset-branch/git-reset-helper.js && node git-reset-helper.js
```

##### Option 2: Clone and run locally
Copy & paste it to your terminal:
```bash
git clone https://github.com/F00L1X/wsflx.git; cd wsflx/git/git-reset-branch; node git-reset-helper.js
```

[📚 Learn more about Git Reset Helper](git/git-reset-branch/readme.md)

### 📊 CSV Duplicate Remover

Remove duplicate rows from CSV files with a user-friendly GUI and automatic encoding fix for German umlauts and special characters.

#### 🚀 Quick Start

##### Option 1: Download and run (recommended)
Copy & paste it to your terminal:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/F00L1X/wsflx/main/excel/RemoveDuplicates.ps1" -OutFile "$env:TEMP\RemoveDuplicates.ps1";Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:TEMP\RemoveDuplicates.ps1" -GUI
```

##### Option 2: Clone and run locally
Copy & paste it to your terminal:
```powershell
git clone https://github.com/F00L1X/wsflx.git; cd wsflx/excel; Set-ExecutionPolicy Bypass -Scope Process -Force; .\RemoveDuplicates.ps1 -GUI
```

[📚 Learn more about CSV Duplicate Remover](excel/readme.md)

## 🔜 Coming Soon

More scripts for:
- 🧰 System cleanup and optimization
- 👨‍💻 Development environment setup
- 🎨 Windows customization
- 🛠️ Productivity tools installation

## 🙌 Contributions

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

If you find these scripts helpful, please ⭐ star the repository and share it with others!
