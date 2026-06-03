<#
.SYNOPSIS
    Flush every cache layer that can make a freshly-pushed change NOT show up in the browser.

.DESCRIPTION
    After a deploy (e.g. Coolify auto-deploy) or a DNS change (e.g. Cloudflare orange->grey
    cutover), the new state is live on the server but the local machine keeps serving stale
    data from one of several caches. This script clears them all:

      1. OS DNS resolver cache        (stale A/AAAA records, e.g. old proxied Cloudflare IPs)
      2. ARP + NetBIOS caches         (optional, admin-only)
      3. Browser HTTP / code / GPU caches
      4. Browser SERVICE WORKER caches (the #1 cause of a SPA showing old content)
      5. Browser Alt-Svc / QUIC state  (the cause of ERR_QUIC_PROTOCOL_ERROR after a CF cutover)

    Cookies, saved logins, history and preferences are NOT touched.

    Browser caches are file-locked while the browser runs. Use -CloseBrowsers to close the
    supported browsers first (gracefully, then forced) so their caches can actually be cleared.

.PARAMETER DnsOnly
    Only flush DNS / network caches. Does not touch browsers. Fast and safe to run anytime.

.PARAMETER CloseBrowsers
    Close running supported browsers (Chrome, Edge, Brave, Vivaldi, Firefox) before clearing
    their caches. Without this, a running browser's cache is skipped (its files are locked).

.PARAMETER Browser
    Limit browser clearing to specific browsers. Default: all supported.
    Valid: Chrome, Edge, Brave, Vivaldi, Firefox

.EXAMPLE
    .\Flush-WebCaches.ps1 -DnsOnly
    Just flush DNS (e.g. right after a Cloudflare DNS change).

.EXAMPLE
    .\Flush-WebCaches.ps1 -CloseBrowsers
    Full flush: DNS + close all browsers + clear their caches/service-workers/QUIC state.

.NOTES
    Run elevated to also clear ARP/NetBIOS. DNS + browser clearing work without admin.
#>
[CmdletBinding()]
param(
    [switch]$DnsOnly,
    [switch]$CloseBrowsers,
    [ValidateSet('Chrome', 'Edge', 'Brave', 'Vivaldi', 'Firefox')]
    [string[]]$Browser
)

$ErrorActionPreference = 'Continue'

# ---------- output helpers ----------
function Write-Step([string]$m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-Ok([string]$m)   { Write-Host "    [ok]   $m" -ForegroundColor Green }
function Write-Skip([string]$m) { Write-Host "    [skip] $m" -ForegroundColor DarkGray }
function Write-Warn2([string]$m){ Write-Host "    [warn] $m" -ForegroundColor Yellow }

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Tracks freed bytes
$script:Freed = 0

function Get-PathSize([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return 0 }
    try {
        $sum = (Get-ChildItem -LiteralPath $path -Recurse -Force -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
        if ($null -eq $sum) { return 0 }
        return [int64]$sum
    } catch { return 0 }
}

# Remove a directory's CONTENTS (keeps the dir itself so the browser re-creates cleanly),
# or delete a single file. Returns $true if anything was removed.
function Clear-Target([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    $size = Get-PathSize $path
    try {
        if (Test-Path -LiteralPath $path -PathType Container) {
            Get-ChildItem -LiteralPath $path -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction Stop
        } else {
            Remove-Item -LiteralPath $path -Force -ErrorAction Stop
        }
        $script:Freed += $size
        return $true
    } catch {
        Write-Warn2 "locked/in-use, could not clear: $path"
        return $false
    }
}

function Format-Bytes([int64]$b) {
    if ($b -ge 1GB) { return ('{0:N2} GB' -f ($b / 1GB)) }
    if ($b -ge 1MB) { return ('{0:N1} MB' -f ($b / 1MB)) }
    if ($b -ge 1KB) { return ('{0:N0} KB' -f ($b / 1KB)) }
    return "$b B"
}

# ---------- 1) DNS / network ----------
function Invoke-DnsFlush {
    Write-Step 'Flushing DNS resolver cache'
    try { Clear-DnsClientCache -ErrorAction Stop; Write-Ok 'Clear-DnsClientCache' }
    catch { ipconfig /flushdns | Out-Null; Write-Ok 'ipconfig /flushdns' }

    Write-Step 'Re-registering DNS'
    ipconfig /registerdns | Out-Null
    Write-Ok 'ipconfig /registerdns'

    if (Test-Admin) {
        Write-Step 'Flushing ARP + NetBIOS caches (admin)'
        try { netsh interface ip delete arpcache | Out-Null; Write-Ok 'ARP cache cleared' }
        catch { Write-Warn2 'ARP flush failed' }
        try { nbtstat -R  | Out-Null; nbtstat -RR | Out-Null; Write-Ok 'NetBIOS cache cleared' }
        catch { Write-Warn2 'NetBIOS flush failed' }
    } else {
        Write-Skip 'ARP/NetBIOS need an elevated shell (run as Administrator) - skipped'
    }
}

# ---------- 2) browsers ----------
# name -> @{ Proc=<process names>; Root=<User Data path>; Type='chromium'|'firefox' }
$BrowserMap = [ordered]@{
    Chrome  = @{ Proc = @('chrome');  Root = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data';              Type = 'chromium' }
    Edge    = @{ Proc = @('msedge');  Root = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data';             Type = 'chromium' }
    Brave   = @{ Proc = @('brave');   Root = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'; Type = 'chromium' }
    Vivaldi = @{ Proc = @('vivaldi'); Root = Join-Path $env:LOCALAPPDATA 'Vivaldi\User Data';                    Type = 'chromium' }
    Firefox = @{ Proc = @('firefox'); Root = Join-Path $env:APPDATA      'Mozilla\Firefox\Profiles';             Type = 'firefox'  }
}

function Stop-BrowserProcess([string[]]$names) {
    $running = Get-Process -Name $names -ErrorAction SilentlyContinue
    if (-not $running) { return $false }
    foreach ($p in $running) { try { $p.CloseMainWindow() | Out-Null } catch {} }
    Start-Sleep -Milliseconds 1500
    $still = Get-Process -Name $names -ErrorAction SilentlyContinue
    if ($still) { try { $still | Stop-Process -Force -ErrorAction Stop } catch {} ; Start-Sleep -Milliseconds 500 }
    return $true
}

# Subpaths to clear inside each Chromium profile. Caches + service workers + QUIC/Alt-Svc state.
# NOT cleared: Cookies, Login Data, History, Preferences.
$ChromiumProfileTargets = @(
    'Cache',
    'Code Cache',
    'GPUCache',
    'DawnGraphiteCache',
    'DawnWebGPUCache',
    'Service Worker\CacheStorage',
    'Service Worker\ScriptCache',
    'Service Worker\Database',
    'Network\Network Persistent State',   # Alt-Svc / broken-QUIC list  -> fixes ERR_QUIC_PROTOCOL_ERROR
    'Network\Reporting and NEL'
)

function Clear-ChromiumBrowser([string]$label, [string]$root) {
    if (-not (Test-Path -LiteralPath $root)) { Write-Skip "$label not installed"; return }
    Write-Step "Clearing $label caches"
    # profile dirs: Default, Profile 1.., Guest Profile, System Profile
    $profiles = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile *' -or $_.Name -like '*Profile' }
    if (-not $profiles) { Write-Skip "$label - no profiles found"; return }
    foreach ($prof in $profiles) {
        $cleared = 0
        foreach ($sub in $ChromiumProfileTargets) {
            if (Clear-Target (Join-Path $prof.FullName $sub)) { $cleared++ }
        }
        if ($cleared) { Write-Ok "$label / $($prof.Name): cleared $cleared cache target(s)" }
        else { Write-Skip "$label / $($prof.Name): nothing to clear" }
    }
}

function Clear-FirefoxBrowser([string]$root) {
    if (-not (Test-Path -LiteralPath $root)) { Write-Skip 'Firefox not installed'; return }
    Write-Step 'Clearing Firefox caches'
    # On-disk cache lives under LocalAppData, not Roaming.
    $localRoot = Join-Path $env:LOCALAPPDATA 'Mozilla\Firefox\Profiles'
    $profiles = @()
    if (Test-Path $localRoot) { $profiles += Get-ChildItem -LiteralPath $localRoot -Directory -ErrorAction SilentlyContinue }
    if (-not $profiles) { Write-Skip 'Firefox - no profiles found'; return }
    foreach ($prof in $profiles) {
        $cleared = 0
        foreach ($sub in @('cache2', 'startupCache', 'OfflineCache')) {
            if (Clear-Target (Join-Path $prof.FullName $sub)) { $cleared++ }
        }
        if ($cleared) { Write-Ok "Firefox / $($prof.Name): cleared $cleared cache target(s)" }
        else { Write-Skip "Firefox / $($prof.Name): nothing to clear" }
    }
    Write-Warn2 'Firefox stores Alt-Svc in SQLite; if QUIC issues persist, clear it via the browser UI.'
}

function Invoke-BrowserFlush {
    $targets = $BrowserMap.Keys
    if ($Browser) { $targets = $Browser }

    foreach ($name in $targets) {
        $info = $BrowserMap[$name]
        $isRunning = [bool](Get-Process -Name $info.Proc -ErrorAction SilentlyContinue)
        if ($isRunning) {
            if ($CloseBrowsers) {
                Write-Step "Closing $name"
                Stop-BrowserProcess $info.Proc | Out-Null
                Write-Ok "$name closed"
            } else {
                Write-Warn2 "$name is running - its locked caches will be skipped. Re-run with -CloseBrowsers."
            }
        }
        if ($info.Type -eq 'chromium') { Clear-ChromiumBrowser $name $info.Root }
        else { Clear-FirefoxBrowser $info.Root }
    }
}

# ---------- run ----------
Write-Host "Flush-WebCaches" -ForegroundColor White
Write-Host ("Admin: {0} | Mode: {1}" -f (Test-Admin), $(if ($DnsOnly) { 'DNS only' } else { 'DNS + browsers' }))

Invoke-DnsFlush

if (-not $DnsOnly) {
    Invoke-BrowserFlush
}

Write-Host ("`nDone. Freed ~{0} of browser cache." -f (Format-Bytes $script:Freed)) -ForegroundColor White
if (-not $DnsOnly -and -not $CloseBrowsers) {
    Write-Host "Tip: pass -CloseBrowsers for a complete clear (running browsers lock their cache files)." -ForegroundColor DarkGray
}
Write-Host "Tip: in the page, a hard reload (Ctrl+F5) or DevTools > Network > 'Disable cache' also helps." -ForegroundColor DarkGray

# Native tools (ipconfig/nbtstat) may leave a non-zero $LASTEXITCODE; the script itself succeeded.
exit 0
