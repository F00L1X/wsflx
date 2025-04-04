##############################################################
# Date: 04.04.2025
# Author: F00l1x
# Updated by: F00l1x
# ScriptVersion: 1.0
# Description: Script to revert Windows 11 UI customizations back to defaults
##############################################################

# Ask for elevated permissions if required
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Error handling settings
$ErrorActionPreference = "SilentlyContinue"
$global:ErrorOccurred = $false

# Set script execution settings
Set-StrictMode -Version Latest
$PSDefaultParameterValues['*:ErrorAction'] = 'SilentlyContinue'

############################ FUNCTIONS SECTION #############################

# Function to handle errors and provide feedback
function Write-TweakLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Type = "Info"
    )

    switch ($Type) {
        "Info"    { $Color = "White";  $Prefix = "[INFO] " }
        "Warning" { $Color = "Yellow"; $Prefix = "[WARNING] "; $global:ErrorOccurred = $true }
        "Error"   { $Color = "Red";    $Prefix = "[ERROR] ";   $global:ErrorOccurred = $true }
        "Success" { $Color = "Green";  $Prefix = "[SUCCESS] " }
    }

    Write-Host "$Prefix$Message" -ForegroundColor $Color
}

function Take-Ownership {
<#
.SYNOPSIS
 Give ownership of a file or folder to the specified user.

.DESCRIPTION
 Give the current process the SeTakeOwnershipPrivilege" and "SeRestorePrivilege" rights which allows it
 to reset ownership of an object.  The script will then set the owner to be the specified user.

.PARAMETER Path (Required)
 The path to the object on which you wish to change ownership.  It can be a file or a folder.

.PARAMETER User (Required)
 The user whom you want to be the owner of the specified object.  The user should be in the format
 <domain>\<username>.  Other user formats will not work.  For system accounts, such as System, the user
 should be specified as "NT AUTHORITY\System".  If the domain is missing, the local machine will be assumed.

.PARAMETER Recurse (switch)
 Causes the function to parse through the Path recursively.

.INPUTS
 None. You cannot pipe objects to Take-Ownership

.OUTPUTS
 None

.NOTES
 Name:    Take-Ownership.ps1
 Author:  Jason Eberhardt
 Date:    2017-07-20
#>

  [CmdletBinding(SupportsShouldProcess=$false)]
  Param([Parameter(Mandatory=$true, ValueFromPipeline=$false)] [ValidateNotNullOrEmpty()] [string]$Path,
        [Parameter(Mandatory=$true, ValueFromPipeline=$false)] [ValidateNotNullOrEmpty()] [string]$User,
        [Parameter(Mandatory=$false, ValueFromPipeline=$false)] [switch]$Recurse)

Begin {
$AdjustTokenPrivileges=@"
using System;
using System.Runtime.InteropServices;

  public class TokenManipulator {
    [DllImport("kernel32.dll", ExactSpelling = true)]
      internal static extern IntPtr GetCurrentProcess();

    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
      internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
      internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
    [DllImport("advapi32.dll", SetLastError = true)]
      internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct TokPriv1Luid {
      public int Count;
      public long Luid;
      public int Attr;
    }

    internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
    internal const int TOKEN_QUERY = 0x00000008;
    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;

    public static bool AddPrivilege(string privilege) {
      bool retVal;
      TokPriv1Luid tp;
      IntPtr hproc = GetCurrentProcess();
      IntPtr htok = IntPtr.Zero;
      retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
      tp.Count = 1;
      tp.Luid = 0;
      tp.Attr = SE_PRIVILEGE_ENABLED;
      retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
      retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
      return retVal;
    }

    public static bool RemovePrivilege(string privilege) {
      bool retVal;
      TokPriv1Luid tp;
      IntPtr hproc = GetCurrentProcess();
      IntPtr htok = IntPtr.Zero;
      retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
      tp.Count = 1;
      tp.Luid = 0;
      tp.Attr = SE_PRIVILEGE_DISABLED;
      retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
      retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
      return retVal;
    }
  }
"@
  }

  Process {
    $Item=Get-Item $Path
    Write-Host "Giving current process token ownership rights"
    Add-Type $AdjustTokenPrivileges -PassThru > $null
    [void][TokenManipulator]::AddPrivilege("SeTakeOwnershipPrivilege")
    [void][TokenManipulator]::AddPrivilege("SeRestorePrivilege")

    # Change ownership
    $Account=$User.Split("\")
    if ($Account.Count -eq 1) { $Account+=$Account[0]; $Account[0]=$env:COMPUTERNAME }
    $Owner=New-Object System.Security.Principal.NTAccount($Account[0],$Account[1])
    Write-Host "Change ownership to '$($Account[0])\$($Account[1])'"

    $Provider=$Item.PSProvider.Name
    if ($Item.PSIsContainer) {
      switch ($Provider) {
        "FileSystem" { $ACL=[System.Security.AccessControl.DirectorySecurity]::new() }
        "Registry"   { $ACL=[System.Security.AccessControl.RegistrySecurity]::new()
                       # Get-Item doesn't open the registry in a way that we can write to it.
                       switch ($Item.Name.Split("\")[0]) {
                         "HKEY_CLASSES_ROOT"   { $rootKey=[Microsoft.Win32.Registry]::ClassesRoot; break }
                         "HKEY_LOCAL_MACHINE"  { $rootKey=[Microsoft.Win32.Registry]::LocalMachine; break }
                         "HKEY_CURRENT_USER"   { $rootKey=[Microsoft.Win32.Registry]::CurrentUser; break }
                         "HKEY_USERS"          { $rootKey=[Microsoft.Win32.Registry]::Users; break }
                         "HKEY_CURRENT_CONFIG" { $rootKey=[Microsoft.Win32.Registry]::CurrentConfig; break }
                       }
                       $Key=$Item.Name.Replace(($Item.Name.Split("\")[0]+"\"),"")
                       $Item=$rootKey.OpenSubKey($Key,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership) }
        default { throw "Unknown provider:  $($Item.PSProvider.Name)" }
      }
      $ACL.SetOwner($Owner)
      Write-Host "Setting owner on $Path"
      $Item.SetAccessControl($ACL)
      if ($Provider -eq "Registry") { $Item.Close() }

      if ($Recurse.IsPresent) {
        # You can't set ownership on Registry Values
        if ($Provider -eq "Registry") { $Items=Get-ChildItem -Path $Path -Recurse -Force | Where-Object { $_.PSIsContainer } }
        else { $Items=Get-ChildItem -Path $Path -Recurse -Force }
        $Items=@($Items)
        for ($i=0; $i -lt $Items.Count; $i++) {
          switch ($Provider) {
            "FileSystem" { $Item=Get-Item $Items[$i].FullName
                           if ($Item.PSIsContainer) { $ACL=[System.Security.AccessControl.DirectorySecurity]::new() }
                           else { $ACL=[System.Security.AccessControl.FileSecurity]::new() } }
            "Registry"   { $Item=Get-Item $Items[$i].PSPath
                           $ACL=[System.Security.AccessControl.RegistrySecurity]::new()
                           # Get-Item doesn't open the registry in a way that we can write to it.
                           switch ($Item.Name.Split("\")[0]) {
                             "HKEY_CLASSES_ROOT"   { $rootKey=[Microsoft.Win32.Registry]::ClassesRoot; break }
                             "HKEY_LOCAL_MACHINE"  { $rootKey=[Microsoft.Win32.Registry]::LocalMachine; break }
                             "HKEY_CURRENT_USER"   { $rootKey=[Microsoft.Win32.Registry]::CurrentUser; break }
                             "HKEY_USERS"          { $rootKey=[Microsoft.Win32.Registry]::Users; break }
                             "HKEY_CURRENT_CONFIG" { $rootKey=[Microsoft.Win32.Registry]::CurrentConfig; break }
                           }
                           $Key=$Item.Name.Replace(($Item.Name.Split("\")[0]+"\"),"")
                           $Item=$rootKey.OpenSubKey($Key,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership) }
            default { throw "Unknown provider:  $($Item.PSProvider.Name)" }
          }
          $ACL.SetOwner($Owner)
          Write-Host "Setting owner on $($Item.Name)"
          $Item.SetAccessControl($ACL)
          if ($Provider -eq "Registry") { $Item.Close() }
        }
      } # Recursion
    }
    else {
      if ($Recurse.IsPresent) { Write-Warning "Object specified is neither a folder nor a registry key.  Recursion is not possible." }
      switch ($Provider) {
        "FileSystem" { $ACL=[System.Security.AccessControl.FileSecurity]::new() }
        "Registry"   { throw "You cannot set ownership on a registry value"  }
        default { throw "Unknown provider:  $($Item.PSProvider.Name)" }
      }
      $ACL.SetOwner($Owner)
      Write-Host "Setting owner on $Path"
      $Item.SetAccessControl($ACL)
    }
  }
}

function CheckExplorer {
<#
.Synopsis
Checks and Restarts Explorer if necessary

.Description
This Function can detect if the Explorer.exe which holds the Taskbar exists.
If not it starts a new Explorer instance in the name of the current User.
Restart can be forced

.PARAMETER ForceRestart
If set the Explorer will be closed and Restarted regardless of state.
e.g. -ForceRestart

.EXAMPLE
CheckExplorer -ForceRestart

.LINK
https://superuser.com/questions/511914/why-does-explorer-restart-automatically-when-i-kill-it-with-process-kill

.NOTES
 Name:    Check_Explorer.ps1
 Author:  Hugo Bergmann // F00l1x
 Date:    2019-03-15
#>

  param([Switch]$ForceRestart = $False)

if (-not ([System.Management.Automation.PSTypeName]'same2u.net.Util').Type){
# This Helper Returns the Explorer.exe Process ID which handles the Taskbar
# The Helper is used with "$ExplorerProcessID = [same2u.net.Util]::GetTaskbarProcessID()"
Add-Type -Namespace same2u.net -Name Util -MemberDefinition @"
[DllImport("user32.dll", SetLastError=true)]
static extern IntPtr FindWindow(string lpszClass, string lpszWindow);

[DllImport("user32.dll", SetLastError=true)]
static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

static IntPtr GetTaskbarHwnd() { return FindWindow("Shell_TrayWnd", null); }
public static uint GetTaskbarProcessId() { uint pid; GetWindowThreadProcessId(GetTaskbarHwnd(), out pid); return pid; }
"@
}
  Write-TweakLog -Message ([String]$MyInvocation.MyCommand+ ":: Checking if Explorer.exe is still active...") -Type Info
  if(!!$ForceRestart -and !![same2u.net.Util]::GetTaskbarProcessID()){
      if ( !!(Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoRestartShell") -and !!([same2u.net.Util]::GetTaskbarProcessID()) ){
          $SelfRestart = $True
          Write-TweakLog -Message ([String]$MyInvocation.MyCommand+ ":: ForcedRestart = True, Windows Auto Restart Enabled, Explorer will restart automatically after closing.") -Type Info
      }
      Write-TweakLog -Message ([String]$MyInvocation.MyCommand+ ":: ForcedRestart = True, Closing Explorer.exe") -Type Info
      Stop-Process -Id ([same2u.net.Util]::GetTaskbarProcessID()) -Force
  }
  if(!([same2u.net.Util]::GetTaskbarProcessID()) -and !$SelfRestart ){
      Write-TweakLog -Message ([String]$MyInvocation.MyCommand+ ":: Explorer NOT active, restarting Explorer.exe") -Type Info

      # Restarting Explorer.exe via Windows Tasks
      try {
          $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
          schtasks /create /s $env:COMPUTERNAME /tn "RunExplorer" /F /sc once /tr "Explorer.exe" /st 23:59 /ru $currentUser
          schtasks /run /tn "RunExplorer"
          schtasks /delete /tn "RunExplorer" /f
      }
      catch {
          Write-TweakLog -Message "Failed to restart Explorer via scheduled task. Trying alternative method." -Type Warning
          Start-Process -FilePath "explorer.exe"
      }
  }
  else {
      Write-TweakLog -Message ([String]$MyInvocation.MyCommand+ ":: Explorer.exe will start shortly or is already active, no further action needed") -Type Info
  }
}

function Show-MessageBox {
<#
.Synopsis
Displays a Message Box to User
#>

  [CmdletBinding(PositionalBinding=$false)]
  param(
      [Parameter(Mandatory = $True,
      HelpMessage='Enter Your Text with -Text "Your Text".')]
      [String]$Text,
      [Parameter(Mandatory = $True,
      HelpMessage='Enter Your Message Box Title with -Title "Your Title".')]
      [String]$Title,
      [ValidateSet('OKOnly', 'OKCancel', 'Yes_No', 'Yes_No_Cancel', 'Retry_Cancel', 'Abort_Retry_Ignore', 'Cancel_TryAgain_Continue')]
      [String]$Buttons = "OKOnly",
      [ValidateSet('Information', 'Question', 'Warning', 'Stop') ]
      [String]$Style = "Information",
      [Switch]$Topmost = $True,
      [int]$TimeoutSeconds = 0,
      [Switch]$NumericReturn = $False,
      [ValidateSet('FirstButton', 'SecondButton', 'ThirdButton') ]
      [String]$DefaultButton = "FirstButton",
      [Switch]$TextRightAlign = $False,
      [Switch]$RightToLeftReadMode = $False
  )
  $ComObject = new-object -comobject wscript.shell
  [Int]$Optional = 0
  switch($Buttons){
      'OKCancel'                {$Optional += 1}
      'Yes_No'                  {$Optional += 4}
      'Yes_No_Cancel'           {$Optional += 3}
      'Retry_Cancel'            {$Optional += 5}
      'Abort_Retry_Ignore'      {$Optional += 2}
      'Cancel_TryAgain_Continue'{$Optional += 6} }
  switch($Style){
      'Stop'        {$Optional += 16}
      'Question'    {$Optional += 32}
      'Warning'     {$Optional += 48}
      'Information' {$Optional += 64} }
  switch($DefaultButton){
      'SecondButton' {$Optional += 256}
      'ThirdButton'  {$Optional += 512} }
  Write-TweakLog -Message ([String]$MyInvocation.MyCommand+ ":: Showing Messagebox -> Button configuration = $Buttons, Style = $Style, Topmost is $Topmost, Numeric Return is $NumericReturn, Timeout is $TimeoutSeconds seconds (Zero is infinite), Default Button is $DefaultButton") -Type Info
  if($Topmost){ $Optional += 4096}
  if($TextRightAlign){$Optional += 524288;Write-TweakLog -Message ([String]$MyInvocation.MyCommand+ ":: Align text to right side is $TextRightAlign") -Type Info}
  if($RightToLeftReadMode){$Optional += 1048576;Write-TweakLog -Message ([String]$MyInvocation.MyCommand+ ":: Right to Left Read Mode is $RightToLeftReadMode") -Type Info}
  $Answer = $ComObject.popup($Text,$TimeoutSeconds,$Title,$Optional)
  switch ($Answer){
      -1 {$Return = "Timeout"}
      1  {$Return = "OK"}
      2  {$Return = "Cancel"}
      3  {$Return = "Abort"}
      4  {$Return = "Retry"}
      5  {$Return = "Ignore"}
      6  {$Return = "Yes"}
      7  {$Return = "No"}
      10 {$Return = "TryAgain"}
      11 {$Return = "Continue"} }
  Write-TweakLog -Message ([String]$MyInvocation.MyCommand+ ":: User Answer is: $Answer -> $Return") -Type Info
  if($NumericReturn){$Return = $Answer}
  if(!!$ComObject){[void][System.Runtime.InteropServices.Marshal]::ReleaseComObject( $ComObject )}
  Return $Return
}

# Function to safely modify registry
function Set-RegistryValueSafely {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [object]$Value,

        [Parameter(Mandatory=$false)]
        [string]$Type = "DWord"
    )

    try {
        # Create path if it doesn't exist
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-TweakLog -Message "Created new registry path: $Path" -Type Info
        }

        # Set the registry value
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -ErrorAction Stop
        Write-TweakLog -Message "Successfully set registry value: $Path\$Name = $Value" -Type Success
        return $true
    }
    catch {
        Write-TweakLog -Message "Failed to set registry value $Path\$Name : $_" -Type Error
        return $false
    }
}

# Function to get current user's SID
function Get-CurrentUserSID {
    try {
        $sid = (Get-CimInstance -ClassName Win32_UserAccount | Where-Object -FilterScript {$_.Name -eq $env:USERNAME}).SID
        if ($sid) {
            return $sid
        }
        else {
            # Alternative method if the first fails
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            return $currentUser.User.Value
        }
    }
    catch {
        Write-TweakLog -Message "Failed to get current user SID: $_" -Type Error
        return $null
    }
}

########################## END FUNCTIONS SECTION #########################

# Script execution starts here - main functionality
try {
    # Welcome message
    Write-TweakLog -Message "Starting Windows 11 UI Revert Script v1.0..." -Type Info
    Write-TweakLog -Message "This script will revert Windows 11 UI customizations back to defaults" -Type Info

    # Get current user's SID
    $SID = Get-CurrentUserSID
    if (-not $SID) {
        Write-TweakLog -Message "Unable to determine current user's SID, some operations may fail" -Type Warning
    }

    ###################################################
    # REVERT WINDOWS 11 GUI TWEAKS                    #
    ###################################################

    Write-TweakLog -Message "Reverting Windows 11 GUI tweaks..." -Type Info

    # Restore Windows 11 Context Menu
    $NewContextMenueKeyRenamed = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\-{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
    $NewContextMenueKey = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"

    if (Test-Path $NewContextMenueKeyRenamed) {
        try {
            Write-TweakLog -Message "Restoring Windows 11 context menu using enhanced method..." -Type Info

            # Take ownership with System instead of current user
            Take-Ownership -Path $NewContextMenueKeyRenamed -User "NT AUTHORITY\SYSTEM" -Recurse

            # Add full permissions for SYSTEM
            $acl = Get-Acl $NewContextMenueKeyRenamed
            $person = [System.Security.Principal.NTAccount]"NT AUTHORITY\SYSTEM"
            $access = [System.Security.AccessControl.RegistryRights]"FullControl"
            $inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
            $propagation = [System.Security.AccessControl.PropagationFlags]"None"
            $type = [System.Security.AccessControl.AccessControlType]"Allow"
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($person,$access,$inheritance,$propagation,$type)
            $acl.AddAccessRule($rule)
            $acl | Set-Acl

            # Add Administrators with full control
            $acl = Get-Acl $NewContextMenueKeyRenamed
            $person = [System.Security.Principal.NTAccount]"BUILTIN\Administrators"
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($person,$access,$inheritance,$propagation,$type)
            $acl.AddAccessRule($rule)
            $acl | Set-Acl

            # Try alternative export/import method if direct rename fails
            try {
                Rename-Item $NewContextMenueKeyRenamed $NewContextMenueKey -Force
                Write-TweakLog -Message "Successfully restored Windows 11 context menu with direct rename" -Type Success
            } catch {
                Write-TweakLog -Message "Direct rename failed, trying registry export/import method..." -Type Warning

                # Export the registry key
                $tempFile = "$env:TEMP\context_menu_key.reg"
                reg export "HKLM\SOFTWARE\Classes\CLSID\-{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" $tempFile /y

                # Modify the exported file to change the key name
                $content = Get-Content $tempFile
                $content = $content -replace "-{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}", "{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
                Set-Content $tempFile $content

                # Import modified registry file
                reg import $tempFile

                # Delete renamed key after successful import
                try {
                    Remove-Item -Path $NewContextMenueKeyRenamed -Force -Recurse
                    Write-TweakLog -Message "Successfully restored Windows 11 context menu using export/import method" -Type Success
                } catch {
                    Write-TweakLog -Message "Failed to remove old key, trying direct registry command..." -Type Warning

                    # Final fallback - create new key and delete old one
                    $result = reg add "HKLM\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
                    if ($LASTEXITCODE -eq 0) {
                        # Copy all values from old key to new key (if needed)
                        # Now try to force delete the old key
                        $result = reg delete "HKLM\SOFTWARE\Classes\CLSID\-{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
                        Write-TweakLog -Message "Applied direct registry commands to restore context menu" -Type Info
                    }
                }
            }
        }
        catch {
            Write-TweakLog -Message "Failed to restore Windows 11 context menu: $_" -Type Error
        }
    }
    else {
        Write-TweakLog -Message "Context menu key already in default state" -Type Info
    }

    # Remove old Ribbon Menu in File Explorer (restore default)
    $OldRibbonMenue = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked\{e2bf9676-5f8f-435c-97eb-11607a5bedf7}"
    if (Test-Path $OldRibbonMenue) {
        try {
            # First take ownership of the key
            Write-TweakLog -Message "Removing old ribbon menu using enhanced method..." -Type Info

            Take-Ownership -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" -User "NT AUTHORITY\SYSTEM" -Recurse

            # Set permissions
            $acl = Get-Acl "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked"
            $person = [System.Security.Principal.NTAccount]"BUILTIN\Administrators"
            $access = [System.Security.AccessControl.RegistryRights]"FullControl"
            $inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
            $propagation = [System.Security.AccessControl.PropagationFlags]"None"
            $type = [System.Security.AccessControl.AccessControlType]"Allow"
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($person,$access,$inheritance,$propagation,$type)
            $acl.AddAccessRule($rule)
            $acl | Set-Acl

            # Now try to remove the item
            try {
                Remove-Item -Path $OldRibbonMenue -Force | Out-Null
                Write-TweakLog -Message "Successfully removed old ribbon menu key" -Type Success
            } catch {
                Write-TweakLog -Message "Standard removal failed, trying alternative method..." -Type Warning

                # Try to delete via reg.exe command
                $guid = "{e2bf9676-5f8f-435c-97eb-11607a5bedf7}"
                $result = reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v $guid /f

                if ($result -match "The operation completed successfully") {
                    Write-TweakLog -Message "Successfully removed old ribbon menu registry entry using reg.exe" -Type Success
                } else {
                    throw "Failed to remove using reg.exe"
                }
            }

            # Force a cleanup of Explorer cache
            Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1

            Write-TweakLog -Message "Successfully restored default menu in File Explorer" -Type Success
        }
        catch {
            Write-TweakLog -Message "Failed to restore default menu in File Explorer: $_" -Type Error
        }
    }

    # Default setting: Auto-hide icons in Taskbar
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value 1 -Type DWord

    ###################################################
    # REVERT UI TWEAKS                                #
    ###################################################

    Write-TweakLog -Message "Reverting UI tweaks..." -Type Info

    # Show Search button / box (default setting)
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1 -Type DWord

    # Show Task View button (default setting)
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 1 -Type DWord

    # Use regular size icons in taskbar (default setting)
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Value 0 -Type DWord

    # Default taskbar grouping (Windows 11 default)
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarGlomLevel" -Value 0 -Type DWord

    # Auto-hide tray icons (default setting)
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value 1 -Type DWord

    # Hide known file extensions (default setting)
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 -Type DWord

    # Hide hidden files (default setting)
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 -Type DWord

    # Change default Explorer view to "Home" (Windows 11 default)
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 0 -Type DWord

    # Apply changes by restarting explorer
    $restartExplorer = Show-MessageBox -Text "Do you want to restart Explorer now to apply the default settings?" -Title "Windows 11 UI Revert" -Buttons Yes_No -Style Question -Topmost -NumericReturn
    if ($restartExplorer -eq 6) {
        Write-TweakLog -Message "Restarting Explorer to apply changes" -Type Info
        CheckExplorer -ForceRestart
    }
    else {
        Write-TweakLog -Message "Explorer restart postponed. Some changes will not take effect until Explorer is restarted." -Type Warning
    }

    # Final message
    Write-TweakLog -Message "Windows 11 UI has been successfully restored to default settings!" -Type Success

    if ($global:ErrorOccurred) {
        Write-TweakLog -Message "Some operations encountered warnings or errors. Check the log for details." -Type Warning
    }
}
catch {
    Write-TweakLog -Message "A critical error occurred during script execution: $_" -Type Error
    Show-MessageBox -Text "A critical error occurred during script execution.`n`nError: $_" -Title "Windows 11 UI Revert - Error" -Buttons OKOnly -Style Stop -Topmost
}

Write-TweakLog -Message "Script execution complete" -Type Success