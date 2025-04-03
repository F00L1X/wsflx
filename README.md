# wsflx
Windows Scripts by FLX

[![GitHub stars](https://img.shields.io/github/stars/F00L1X/wsflx?style=social)](https://github.com/F00L1X/wsflx/stargazers)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Platform-Windows%207--11-brightgreen)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

A collection of PowerShell scripts to set up, maintain, clean, and optimize Windows operating systems.

## Available Scripts

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

[Learn more about Terminal Styling](terminal-styling/readme.md)

## 🔜 Coming Soon

More scripts for:
- System cleanup and optimization
- Development environment setup
- Windows customization
- Productivity tools installation

## 🙌 Contributions

Contributions are welcome! Please feel free to submit a Pull Request.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

If you find these scripts helpful, please ⭐ star the repository and share it with others!
