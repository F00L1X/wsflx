# 🧽 Flush Web Caches

A PowerShell tool that clears **every cache layer** that can make a freshly-pushed change *not* show up in your browser — DNS, service workers, HTTP/code/GPU caches, and the Alt-Svc/QUIC state that causes `ERR_QUIC_PROTOCOL_ERROR` after a Cloudflare cutover.

Perfect for the "I deployed but still see the old site" problem after a Coolify auto-deploy, a DNS change, or a Cloudflare orange→grey proxy switch.

> Cookies, saved logins, history, and preferences are **NOT** touched.

## 🚀 Quick Start

### Option 1: Download and run (recommended)
Downloads and runs the script directly without cloning the entire repository.

**Full flush** (DNS + close all browsers + clear caches/service-workers/QUIC state) — paste into your terminal:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/F00L1X/wsflx/main/caching/Flush-WebCaches.ps1" -OutFile "$env:TEMP\Flush-WebCaches.ps1";Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:TEMP\Flush-WebCaches.ps1" -CloseBrowsers
```

**DNS only** (fast, safe anytime, leaves browsers alone):
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/F00L1X/wsflx/main/caching/Flush-WebCaches.ps1" -OutFile "$env:TEMP\Flush-WebCaches.ps1";Set-ExecutionPolicy Bypass -Scope Process -Force; & "$env:TEMP\Flush-WebCaches.ps1" -DnsOnly
```

**What this does:**
1. Downloads the script from GitHub to your temporary folder
2. Temporarily bypasses PowerShell execution policy for this session
3. Runs the flush

> 💡 Run in an **elevated** (Administrator) terminal to also clear the ARP and NetBIOS caches. DNS + browser clearing work fine without admin.

### Option 2: Clone and run locally
Clones the entire repository for offline access and easier updates:
```powershell
git clone https://github.com/F00L1X/wsflx.git; cd wsflx/caching; Set-ExecutionPolicy Bypass -Scope Process -Force; .\Flush-WebCaches.ps1 -CloseBrowsers
```

## ✨ What It Clears

| Layer | What | Why it matters |
|-------|------|----------------|
| **OS DNS resolver** | A/AAAA record cache | Stale IPs (e.g. old proxied Cloudflare addresses) |
| **ARP + NetBIOS** | network-level caches (admin only) | Stale L2/name resolution |
| **HTTP / Code / GPU cache** | Chromium & Firefox on-disk caches | Old JS/CSS/assets |
| **Service Worker caches** | CacheStorage, ScriptCache, Database | **#1 cause of a SPA showing old content** |
| **Alt-Svc / QUIC state** | Network Persistent State | Fixes `ERR_QUIC_PROTOCOL_ERROR` after a CF cutover |

## 🌐 Supported Browsers

Chrome · Edge · Brave · Vivaldi · Firefox

Browser cache files are **locked while the browser runs**. Pass `-CloseBrowsers` to gracefully close (then force-close) the browsers first, otherwise running browsers are skipped.

## ⚙️ Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-DnsOnly` | Only flush DNS / network caches. Does not touch browsers. | `false` |
| `-CloseBrowsers` | Close running browsers before clearing their caches. | `false` |
| `-Browser` | Limit clearing to specific browsers. Valid: `Chrome`, `Edge`, `Brave`, `Vivaldi`, `Firefox`. | all |

## 💡 Examples

```powershell
# Just flush DNS (e.g. right after a Cloudflare DNS change)
.\Flush-WebCaches.ps1 -DnsOnly

# Full flush: DNS + close all browsers + clear caches/service-workers/QUIC
.\Flush-WebCaches.ps1 -CloseBrowsers

# Only clear Chrome and Edge, closing them first
.\Flush-WebCaches.ps1 -CloseBrowsers -Browser Chrome,Edge
```

## 📝 Notes

- After running, a **hard reload** (`Ctrl+F5`) or DevTools → Network → *Disable cache* also helps.
- Firefox stores Alt-Svc in a SQLite DB; if QUIC issues persist there, clear it via the browser UI.
- The script reports roughly how many bytes of browser cache it freed.
- Native tools (`ipconfig`/`nbtstat`) may leave a non-zero exit code; the script itself always exits `0` on success.

## 📂 Files in this Folder

- `Flush-WebCaches.ps1` — Main script
- `readme.md` — This documentation file
