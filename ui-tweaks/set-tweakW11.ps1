##############################################################
# Date: 04.04.2025
# Author: F00l1x
# Updated by: F00l1x
# ScriptVersion: 1.0
# Description: Script to customize Windows 11 UI to user preferences
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
    Write-TweakLog -Message "Giving current process token ownership rights" -Type Info
    Add-Type $AdjustTokenPrivileges -PassThru > $null
    [void][TokenManipulator]::AddPrivilege("SeTakeOwnershipPrivilege")
    [void][TokenManipulator]::AddPrivilege("SeRestorePrivilege")

    # Change ownership
    # Special handling for well-known accounts
    # Check if user is trying to use SYSTEM account in various formats
    if ($User -eq "NT AUTHORITY\SYSTEM" -or $User -eq "SYSTEM" -or $User -like "*\SYSTEM" -or $User -eq "PC\SYSTEM") {
        try {
            $Owner = New-Object System.Security.Principal.NTAccount("NT AUTHORITY", "SYSTEM")
            Write-TweakLog -Message "Change ownership to 'NT AUTHORITY\SYSTEM'" -Type Info
        }
        catch {
            Write-TweakLog -Message "Failed to create SYSTEM account, trying alternative format" -Type Warning
            try {
                $Owner = New-Object System.Security.Principal.NTAccount("SYSTEM")
            }
            catch {
                Write-TweakLog -Message "Failed with SYSTEM, trying LocalSystem" -Type Warning
                $Owner = New-Object System.Security.Principal.NTAccount("LocalSystem")
            }
        }
    }
    elseif ($User -eq "BUILTIN\Administrators" -or $User -eq "Administrators" -or $User -like "*\Administrators") {
        try {
            $Owner = New-Object System.Security.Principal.NTAccount("BUILTIN", "Administrators")
            Write-TweakLog -Message "Change ownership to 'BUILTIN\Administrators'" -Type Info
        }
        catch {
            Write-TweakLog -Message "Failed to create Administrators account, trying alternative format" -Type Warning
            $Owner = New-Object System.Security.Principal.NTAccount("Administrators")
        }
    }
    else {
        # Handle different user account formats
        if ($User -match "^(.+)\\(.+)$") {
            $Account = @($Matches[1], $Matches[2])
        }
        else {
            # If no domain specified, use local computer name
            $Account = @($env:COMPUTERNAME, $User)
        }
        
        try {
            $Owner = New-Object System.Security.Principal.NTAccount($Account[0], $Account[1])
            Write-TweakLog -Message "Change ownership to '$($Account[0])\$($Account[1])'" -Type Info
        }
        catch {
            # If NTAccount creation fails, try with just username
            Write-TweakLog -Message "Failed to create NTAccount with domain, trying local account" -Type Warning
            $Owner = New-Object System.Security.Principal.NTAccount($User)
        }
    }

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
      try {
          $ACL.SetOwner($Owner)
          Write-TweakLog -Message "Setting owner on $Path" -Type Info
          $Item.SetAccessControl($ACL)
      }
      catch {
          Write-TweakLog -Message "Failed to set owner: $_" -Type Warning
      }
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
          try {
              $ACL.SetOwner($Owner)
              Write-TweakLog -Message "Setting owner on $($Item.Name)" -Type Info
              $Item.SetAccessControl($ACL)
          }
          catch {
              Write-TweakLog -Message "Failed to set owner on $($Item.Name): $_" -Type Warning
          }
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
      try {
          $ACL.SetOwner($Owner)
          Write-TweakLog -Message "Setting owner on $Path" -Type Info
          $Item.SetAccessControl($ACL)
      }
      catch {
          Write-TweakLog -Message "Failed to set owner: $_" -Type Warning
      }
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

.Description
This Function can Display a Messagebox for custom Text Messages.
It has the ability to be Topmost and has different Button combinations and Box Style configurations.

.PARAMETER Text
Main Text for Display inside the Message Box
e.g. -Text "My custom Text"

.PARAMETER Title
Text in the Overhead(Title) of the Message Box
e.g. -Title "My Title"

.PARAMETER Buttons
6 different Button Modes.
OKOnly(Standard), OKCancel, Yes_No, Yes_No_Cancel, Retry_Cancel, Abort_Retry_Ignore, Cancel_TryAgain_Continue
e.g. -Buttons Yes_No

.PARAMETER Style
4 different Box Styles.
Information(Standard), Question, Warning, Stop
e.g. -Style Warning

.PARAMETER Topmost
If set, MessageBox will always be on Top of all other Windows.
e.g. -Topmost

.PARAMETER TimeoutSeconds
Time in seconds after the Message Box will close automaticly ->  Return Timeout
0 Seconds -> no Timeout set
e.g. -TimeoutSeconds 15

.PARAMETER NumericReturn
If Set Return will be Numeric instead of Text

.PARAMETER DefaultButton
Sets which of the Buttons are selelected at startup of the MessageBox.
FirstButton(Standard), SecondButton, ThirdButton
If out of Range it will default to FirstButton
e.g. -DefaultButton SecondButton

.PARAMETER TextRightAlign
Aligns all Text, Text and Title to the Right Side
e.g. -TextRightAlign

.PARAMETER RightToLeftReadMode
Mirrors the Buttons and Design of the MessageBox.
Text will be Right Aligned, Title will not.
Used for Arabic and Hebrew Language Systems
e.g. -RightToLeftReadMode

.Write-Output S
[System.Int32] if NumericReturn set, [System.String] if not.
Returns User Answer from the Message Box.
-1 = "Timeout" -> No User Answer
1  = "OK"
2  = "Cancel"
3  = "Abort"
4  = "Retry"
5  = "Ignore"
6  = "Yes"
7  = "No"
10 = "TryAgain"
11 = "Continue"

.EXAMPLE
MessageBox -Text "User Question" -Title "Message Box Title-Text" -Style Question -Buttons Yes_No -DefaultButton SecondButton -NumericReturn -TimeoutSeconds 5 -Topmost

.LINK
https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/windows-scripting/x83z1d9f(v=vs.84)?redirectedfrom=MSDN

.NOTES
 Name:    Check_Explorer.ps1
 Author:  F00l1x // Hugo Bergmann // Stjepan Kikic
 Date:    2019-03-15
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
        # First try using Get-LocalUser (most reliable for Windows 11)
        $localUser = Get-LocalUser -Name $env:USERNAME -ErrorAction SilentlyContinue
        if ($localUser -and $localUser.SID) {
            return $localUser.SID.Value
        }
        
        # Second method using CIM query with proper syntax
        $userAccount = Get-CimInstance -Query "Select * from Win32_UserAccount WHERE Name='$env:USERNAME'" -ErrorAction SilentlyContinue
        if ($userAccount -and $userAccount.SID) {
            return $userAccount.SID
        }
        
        # Third method using .NET (most compatible)
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        if ($currentUser -and $currentUser.User) {
            return $currentUser.User.Value
        }
        
        # Final fallback using NTAccount translation
        $objUser = New-Object System.Security.Principal.NTAccount($env:USERDOMAIN, $env:USERNAME)
        $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        return $strSID.Value
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
    Write-TweakLog -Message "Starting Windows 11 UI Tweaks Script v1.0..." -Type Info
    Write-TweakLog -Message "This script will customize the Windows 11 UI to be more user-friendly" -Type Info

    # Get current user's SID
    $SID = Get-CurrentUserSID
    if (-not $SID) {
        Write-TweakLog -Message "Unable to determine current user's SID, some operations may fail" -Type Warning
    }

    ###################################################
    # WINDOWS 11 GUI TWEAKS                           #
    ###################################################

    Write-TweakLog -Message "Applying Windows 11 GUI tweaks..." -Type Info

    # Old Context Menu - Multiple approaches
    Write-TweakLog -Message "Setting Windows 10-style context menu..." -Type Info
    
    # Method 1: Registry rename approach (requires elevated permissions)
    $NewContextMenueKeyRenamed = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\-{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
    $NewContextMenueKey = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"

    $contextMenuSet = $false
    
    if (Test-Path $NewContextMenueKeyRenamed) {
        Write-TweakLog -Message "Context menu key already renamed" -Type Info
        $contextMenuSet = $true
    }
    else {
        try {
            # Try multiple approaches for taking ownership
            $ownershipSet = $false
            
            # Try with full domain\username format first
            try {
                $fullUserName = "$env:USERDOMAIN\$env:USERNAME"
                Take-Ownership -Path $NewContextMenueKey -User $fullUserName -Recurse
                $ownershipSet = $true
            }
            catch {
                Write-TweakLog -Message "Failed with domain\username format, trying alternative methods" -Type Warning
            }
            
            # If that fails, try with BUILTIN\Administrators
            if (-not $ownershipSet) {
                try {
                    Take-Ownership -Path $NewContextMenueKey -User "BUILTIN\Administrators" -Recurse
                    $ownershipSet = $true
                }
                catch {
                    Write-TweakLog -Message "Failed with BUILTIN\Administrators, trying NT AUTHORITY\SYSTEM" -Type Warning
                }
            }
            
            # Final attempt with NT AUTHORITY\SYSTEM
            if (-not $ownershipSet) {
                try {
                    Take-Ownership -Path $NewContextMenueKey -User "NT AUTHORITY\SYSTEM" -Recurse
                    $ownershipSet = $true
                }
                catch {
                    Write-TweakLog -Message "All ownership attempts failed, proceeding with current permissions" -Type Warning
                }
            }

            $acl = Get-Acl $NewContextMenueKey
            $person = [System.Security.Principal.NTAccount]"EVERYONE"
            $access = [System.Security.AccessControl.RegistryRights]"FullControl"
            $inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
            $propagation = [System.Security.AccessControl.PropagationFlags]"None"
            $type = [System.Security.AccessControl.AccessControlType]"Allow"
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule($person,$access,$inheritance,$propagation,$type)
            $acl.AddAccessRule($rule)
            $acl | Set-Acl

            Rename-Item $NewContextMenueKey $NewContextMenueKeyRenamed -Force
            Write-TweakLog -Message "Successfully applied Windows 10-style context menu (Method 1)" -Type Success
            $contextMenuSet = $true
        }
        catch {
            Write-TweakLog -Message "Method 1 failed: $_" -Type Warning
        }
    }
    
    # Method 2: User-specific registry approach (doesn't require system-level permissions)
    if (-not $contextMenuSet) {
        try {
            Write-TweakLog -Message "Trying user-specific context menu settings..." -Type Info
            
            # Disable Windows 11 context menu for current user
            Set-RegistryValueSafely -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" -Type String
            
            Write-TweakLog -Message "Successfully applied Windows 10-style context menu (Method 2)" -Type Success
            $contextMenuSet = $true
        }
        catch {
            Write-TweakLog -Message "Method 2 failed: $_" -Type Warning
        }
    }
    
    # Method 3: Group Policy approach (if available)
    if (-not $contextMenuSet) {
        try {
            Write-TweakLog -Message "Trying Group Policy approach..." -Type Info
            
            # Set registry value to disable new context menu
            Set-RegistryValueSafely -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableContextMenusInStart" -Value 1 -Type DWord
            
            Write-TweakLog -Message "Applied context menu policy settings" -Type Info
        }
        catch {
            Write-TweakLog -Message "Method 3 failed: $_" -Type Warning
        }
    }

    # Get old Ribbon Menu in File Explorer
    $OldRibbonMenue = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked\{e2bf9676-5f8f-435c-97eb-11607a5bedf7}"
    if (!(Test-Path $OldRibbonMenue)) {
        try {
            New-Item -Path $OldRibbonMenue -Force | Out-Null
            Write-TweakLog -Message "Successfully applied old ribbon menu in File Explorer" -Type Success
        }
        catch {
            Write-TweakLog -Message "Failed to set old ribbon menu in File Explorer: $_" -Type Error
        }
    }

    # Show all icons in Taskbar
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value 0 -Type DWord

    ###################################################
    # UI TWEAKS                                       #
    ###################################################

    Write-TweakLog -Message "Applying UI tweaks..." -Type Info

    # Hide Search button / box
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord

    # Hide Task View button
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord

    # Show small icons in taskbar
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Value 1 -Type DWord

    # Show titles in taskbar
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarGlomLevel" -Value 1 -Type DWord

    # Show all tray icons
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value 0 -Type DWord

    # Show known file extensions
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord

    # Show hidden files
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord

    # Change default Explorer view to "Computer"
    Set-RegistryValueSafely -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -Type DWord

    # Apply changes by restarting explorer
    $restartExplorer = Show-MessageBox -Text "Do you want to restart Explorer now to apply UI changes?" -Title "Windows 11 UI Tweaks" -Buttons Yes_No -Style Question -Topmost -NumericReturn
    if ($restartExplorer -eq 6) {
        Write-TweakLog -Message "Restarting Explorer to apply changes" -Type Info
        CheckExplorer -ForceRestart
    }
    else {
        Write-TweakLog -Message "Explorer restart postponed. Some changes will not take effect until Explorer is restarted." -Type Warning
    }

    # Final message
    Write-TweakLog -Message "UI Tweaks have been successfully applied!" -Type Success

    if ($global:ErrorOccurred) {
        Write-TweakLog -Message "Some operations encountered warnings or errors. Check the log for details." -Type Warning
    }
}
catch {
    Write-TweakLog -Message "A critical error occurred during script execution: $_" -Type Error
    Show-MessageBox -Text "A critical error occurred during script execution.`n`nError: $_" -Title "Windows 11 UI Tweaks - Error" -Buttons OKOnly -Style Stop -Topmost
}

Write-TweakLog -Message "Script execution complete" -Type Success


# $PowerSettings = Get-WmiObject -Namespace root\cimv2\power -Class Win32_PowerPlan | ForEach-Object {
#     $PlanGuid = $_.InstanceID.Split('\')[-1]
#     $PlanName = $_.ElementName
#     $SubGroups = Get-WmiObject -Namespace root\cimv2\power -Class Win32_PowerPlanSetting | Where-Object { $_.PlanGuid -eq $PlanGuid }

#     [PSCustomObject]@{
#         PlanGuid  = $PlanGuid
#         PlanName  = $PlanName
#         SubGroups = $SubGroups | Group-Object -Property SubGroupGuid | ForEach-Object {
#             $SubGroupGuid = $_.Name
#             $SubGroupName = ($_.Group | Select-Object -First 1).SubGroupName
#             $Settings = $_.Group | ForEach-Object {
#                 [PSCustomObject]@{
#                     SettingGuid  = $_.SettingGuid
#                     SettingName  = $_SettingName
#                     SettingValue = $_SettingValue
#                 }
#             }
#             [PSCustomObject]@{
#                 SubGroupGuid = $SubGroupGuid
#                 SubGroupName = $SubGroupName
#                 Settings     = $Settings
#             }
#         }
#     }
# }

# # Now $PowerSettings contains the power settings.
# # Example: Accessing the first power plan's name:
# $PowerSettings[0].PlanName

# #Example: Accessing the first subgroup of the first power plan
# $PowerSettings[0].SubGroups[0].SubGroupName

# #Example: Accessing the first setting within the first subgroup of the first power plan
# $PowerSettings[0].SubGroups[0].Settings[0].SettingName

# #Example: Accessing the value of the first setting within the first subgroup of the first power plan
# $PowerSettings[0].SubGroups[0].Settings[0].SettingValue

# #Example : Displaying all power plans
# $PowerSettings | Format-List -Property PlanName, PlanGuid, SubGroups

# #Example : Displaying all settings of a specific plan. Replace the GUID with your plans guid.
# $PowerSettings | Where-Object { $_.PlanGuid -eq "your-plan-guid-here" } | Select-Object -ExpandProperty SubGroups | Select-Object -ExpandProperty Settings