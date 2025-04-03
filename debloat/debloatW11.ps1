##############################################################
# Date 17.09.2021 (Updated: [Current Date])
# Author Felix M. Schneider
# Updated by [Your Name]
# ScriptVersion 2.0
# Description
# Script to Debloat and Tweak Windows 11 with improved error handling and organization
# History
# 17.09.2021 - Initial version
# [Current Date] - Refactored code, improved error handling, enhanced UI
##############################################################

<#
FFFFFFFFFFFFFFFFFFFFFF     000000000          000000000       1111111
F::::::::::::::::::::F   00:::::::::00      00:::::::::00    1::::::1
F::::::::::::::::::::F 00:::::::::::::00  00:::::::::::::00 1:::::::1
FF::::::FFFFFFFFF::::F0:::::::000:::::::00:::::::000:::::::0111:::::1
  F:::::F       FFFFFF0::::::0   0::::::00::::::0   0::::::0   1::::1   xxxxxxx      xxxxxxx
  F:::::F             0:::::0     0:::::00:::::0     0:::::0   1::::1    x:::::x    x:::::x
  F::::::FFFFFFFFFF   0:::::0     0:::::00:::::0     0:::::0   1::::1     x:::::x  x:::::x
  F:::::::::::::::F   0:::::0 000 0:::::00:::::0 000 0:::::0   1::::l      x:::::xx:::::x
  F:::::::::::::::F   0:::::0 000 0:::::00:::::0 000 0:::::0   1::::l       x::::::::::x
  F::::::FFFFFFFFFF   0:::::0     0:::::00:::::0     0:::::0   1::::l        x::::::::x
  F:::::F             0:::::0     0:::::00:::::0     0:::::0   1::::l        x::::::::x
  F:::::F             0::::::0   0::::::00::::::0   0::::::0   1::::l       x::::::::::x
FF:::::::FF           0:::::::000:::::::00:::::::000:::::::0111::::::111   x:::::xx:::::x
F::::::::FF            00:::::::::::::00  00:::::::::::::00 1::::::::::1  x:::::x  x:::::x
F::::::::FF              00:::::::::00      00:::::::::00   1::::::::::1 x:::::x    x:::::x
FFFFFFFFFFF                000000000          000000000     111111111111xxxxxxx      xxxxxxx
                                                                                            #>

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
function Write-DebloatLog {
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

    # Log to file if needed
    # Add-Content -Path "$env:TEMP\DebloatW11_Log.txt" -Value "$(Get-Date) - $Prefix$Message"
}

function Take-Ownership
{
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

Function CheckExplorer {
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
 Author:  Hugo Bergmann // Felix M. Schneider
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
  Write-DebloatLog -Message ([String]$MyInvocation.MyCommand+ ":: Checking if Explorer.exe is still active...") -Type Info
  if(!!$ForceRestart -and !![same2u.net.Util]::GetTaskbarProcessID()){
      if ( !!(Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoRestartShell") -and !!([same2u.net.Util]::GetTaskbarProcessID()) ){
          $SelfRestart = $True
          Write-DebloatLog -Message ([String]$MyInvocation.MyCommand+ ":: ForcedRestart = True, Windows Auto Restart Enabled, Explorer will restart automatically after closing.") -Type Info
      }
      Write-DebloatLog -Message ([String]$MyInvocation.MyCommand+ ":: ForcedRestart = True, Closing Explorer.exe") -Type Info
      Stop-Process -Id ([same2u.net.Util]::GetTaskbarProcessID()) -Force
  }
  if(!([same2u.net.Util]::GetTaskbarProcessID()) -and !$SelfRestart ){
      Write-DebloatLog -Message ([String]$MyInvocation.MyCommand+ ":: Explorer NOT active, restarting Explorer.exe") -Type Info

      # Restarting Explorer.exe via Windows Tasks
      try {
          $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
          schtasks /create /s $env:COMPUTERNAME /tn "RunExplorer" /F /sc once /tr "Explorer.exe" /st 23:59 /ru $currentUser
      schtasks /run /tn "RunExplorer"
      schtasks /delete /tn "RunExplorer" /f
  }
      catch {
          Write-DebloatLog -Message "Failed to restart Explorer via scheduled task. Trying alternative method." -Type Warning
          Start-Process -FilePath "explorer.exe"
      }
  }
  else {
      Write-DebloatLog -Message ([String]$MyInvocation.MyCommand+ ":: Explorer.exe will start shortly or is already active, no further action needed") -Type Info
  }
}

Function Show-MessageBox{
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
 Author:  Felix M. Schneider // Hugo Bergmann // Stjepan Kikic
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
  Write-DebloatLog -Message ([String]$MyInvocation.MyCommand+ ":: Showing Messagebox -> Button configuration = $Buttons, Style = $Style, Topmost is $Topmost, Numeric Return is $NumericReturn, Timeout is $TimeoutSeconds seconds (Zero is infinite), Default Button is $DefaultButton") -Type Info
  if($Topmost){ $Optional += 4096}
  if($TextRightAlign){$Optional += 524288;Write-DebloatLog -Message ([String]$MyInvocation.MyCommand+ ":: Align text to right side is $TextRightAlign") -Type Info}
  if($RightToLeftReadMode){$Optional += 1048576;Write-DebloatLog -Message ([String]$MyInvocation.MyCommand+ ":: Right to Left Read Mode is $RightToLeftReadMode") -Type Info}
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
  Write-DebloatLog -Message ([String]$MyInvocation.MyCommand+ ":: User Answer is: $Answer -> $Return") -Type Info
  if($NumericReturn){$Return = $Answer}
  if(!!$ComObject){[void][System.Runtime.InteropServices.Marshal]::ReleaseComObject( $ComObject )}
  Return $Return
}

# Function to remove AppX packages safely with verification
function Remove-AppxPackageSafely {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName
    )

    try {
        # Check if package exists before attempting removal
        $package = Get-AppxPackage -Name $PackageName -AllUsers -ErrorAction SilentlyContinue

        if ($package) {
            Write-DebloatLog -Message "Attempting to remove package: $PackageName" -Type Info

            # First attempt - standard removal
            Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction SilentlyContinue

            # Check if removal was successful
            $remainingPackage = Get-AppxPackage -Name $PackageName -AllUsers -ErrorAction SilentlyContinue

            if ($remainingPackage) {
                # Second attempt - try alternative method
                Write-DebloatLog -Message "First removal method failed for $PackageName, trying alternative..." -Type Warning
                Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $PackageName | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

                # Final check
                $finalCheck = Get-AppxPackage -Name $PackageName -AllUsers -ErrorAction SilentlyContinue
                if ($finalCheck) {
                    Write-DebloatLog -Message "Unable to completely remove $PackageName" -Type Warning
                    return $false
                }
            }

            Write-DebloatLog -Message "Successfully removed $PackageName" -Type Success
            return $true
        }
        else {
            Write-DebloatLog -Message "Package $PackageName not found" -Type Info
            return $true  # Return true as there's nothing to remove
        }
    }
    catch {
        Write-DebloatLog -Message "Error removing $PackageName : $_" -Type Error
        return $false
    }
}

# Function to create enhanced grid view for package selection
function Show-EnhancedGridView {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object[]]$InputObject,

        [Parameter(Mandatory=$false)]
        [string]$Title = "Select Items",

        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    try {
        # Add custom properties for better display
        $enhancedObjects = $InputObject | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $_.Name -Force -PassThru
        }

        # Set up custom property displays
        $propertiesToDisplay = @('DisplayName', 'Name')

        Write-DebloatLog -Message "Displaying enhanced grid view with $($enhancedObjects.Count) items..." -Type Info

        # Use Out-GridView with custom presentation
        if ($PassThru) {
            return $enhancedObjects | Select-Object $propertiesToDisplay | Out-GridView -Title $Title -PassThru
        }
        else {
            $enhancedObjects | Select-Object $propertiesToDisplay | Out-GridView -Title $Title
            return $null
        }
    }
    catch {
        Write-DebloatLog -Message "Error displaying enhanced grid view: $_" -Type Error

        # Fallback to regular Out-GridView in case of error
        if ($PassThru) {
            return $InputObject | Out-GridView -Title $Title -PassThru
        }
        else {
            $InputObject | Out-GridView -Title $Title
            return $null
        }
    }
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
            Write-DebloatLog -Message "Created new registry path: $Path" -Type Info
        }

        # Set the registry value
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -ErrorAction Stop
        Write-DebloatLog -Message "Successfully set registry value: $Path\$Name = $Value" -Type Success
        return $true
    }
    catch {
        Write-DebloatLog -Message "Failed to set registry value $Path\$Name : $_" -Type Error
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
        Write-DebloatLog -Message "Failed to get current user SID: $_" -Type Error
        return $null
    }
}

########################## END FUNCTIONS #########################

# Script execution starts here - main functionality
try {
    # Welcome message
    Write-DebloatLog -Message "Starting Windows 11 Debloat Script v2.0..." -Type Info
    Write-DebloatLog -Message "This script will remove bloatware and apply recommended tweaks" -Type Info

    # Get current user's SID
    $SID = Get-CurrentUserSID
    if (-not $SID) {
        Write-DebloatLog -Message "Unable to determine current user's SID, some operations may fail" -Type Warning
    }

###################################################
# REMOVE BLOATWARE                                #
###################################################

$Bloatware = @(
        # Default Windows 10/11 AppX apps
        "Microsoft.3DBuilder"
        # "Microsoft.AppConnector"
        "Microsoft.BingFinance"            # Redstone apps
        "Microsoft.BingNews"               # Redstone apps
        "Microsoft.BingSports"             # Redstone apps
        "Microsoft.BingTranslator"         # Redstone apps
        "Microsoft.BingWeather"            # Redstone apps
        "Microsoft.BingFoodAndDrink"       # Redstone apps
        "Microsoft.BingHealthAndFitness"   # Redstone apps
        "Microsoft.BingTravel"             # Redstone apps
        "Microsoft.FreshPaint"
        "Microsoft.GamingApp"
        "Microsoft.GetHelp"
        "Microsoft.Getstarted"
        "Microsoft.GamingServices"
        "Microsoft.Messaging"
        "Microsoft.Microsoft3DViewer"      # Creators Update apps
        "Microsoft.MixedReality.Portal"
        "Microsoft.MicrosoftOfficeHub"
        "Microsoft.MicrosoftPowerBIForWindows"
        "Microsoft.MSPaint"               # Creators Update apps
        "Microsoft.MicrosoftSolitaireCollection"
       # "Microsoft.MicrosoftStickyNotes"
        "Microsoft.MinecraftUWP"
        "Microsoft.NetworkSpeedTest"
        "Microsoft.News"
        "Microsoft.Office.Lens"
        "Microsoft.Office.Sway"
        "Microsoft.Office.OneNote"
        "Microsoft.OneConnect"
       # "Microsoft.Paint"
        "Microsoft.People"
        "Microsoft.Print3D"
        "Microsoft.SkypeApp"
       # "Microsoft.ScreenSketch"
        "Microsoft.StorePurchaseApp"
        "Microsoft.Todos"
       # "Microsoft.WindowsAlarms"
        "Microsoft.windowscommunicationsapps"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.WindowsMaps"
        "Microsoft.Windows.Photos"
        "Microsoft.WindowsSoundRecorder"
       # "Microsoft.WindowsAlarms"
       # "Microsoft.WindowsCalculator"
       # "Microsoft.WindowsCamera"
        "Microsoft.WindowsPhone"
        "Microsoft.WindowsReadingList"        # Redstone apps
        "Microsoft.WindowsSoundRecorder"
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxApp"                   # Redstone apps
       # "Microsoft.XboxGameOverlay"          # Redstone apps
       # "Microsoft.XboxGamingOverlay"        # Redstone apps
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.Wallet"
        "Microsoft.Whiteboard"
        "Microsoft.YourPhone"                 # Redstone apps
        "Microsoft.ZuneMusic"                 # Redstone apps
        "Microsoft.ZuneVideo"                 # Redstone apps

        # apps which other apps depend on
        "Microsoft.Advertising.Xaml"

        # Non-Microsoft apps (sponsored/featured)
        "*EclipseManager*"
        "*ActiproSoftwareLLC*"
        "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
        "*Duolingo-LearnLanguagesforFree*"
        "*PandoraMediaInc*"
        "*CandyCrush*"
        "*BubbleWitch3Saga*"
        "*Wunderlist*"
        "*Flipboard*"
        "*Twitter*"
        "*Facebook*"
        "*Royal Revolt*"
        "*saga*"
        "*Sway*"
        "*Speed Test*"
        "*Dolby*"
        "*Viber*"
        "*ACGMediaPlayer*"
        "*Netflix*"
        "*OneCalendar*"
        "*LinkedInforWindows*"
        "*HiddenCityMysteryofShadows*"
        "*Hulu*"
        "*HiddenCity*"
        "*AdobePhotoshopExpress*"

        # Specific non-Microsoft apps
        "2FE3CB00.PicsArt-PhotoStudio"
        "46928bounde.EclipseManager"
        "4DF9E0F8.Netflix"
        "613EBCEA.PolarrPhotoEditorAcademicEdition"
        "6Wunderkinder.Wunderlist"
        "7EE7776C.LinkedInforWindows"
        "89006A2E.AutodeskSketchBook"
        "9E2F88E3.Twitter"
        "A278AB0D.DisneyMagicKingdoms"
        "A278AB0D.MarchofEmpires"
        "ActiproSoftwareLLC.562882FEEB491" # Code Writer from Actipro Software LLC
        "CAF9E577.Plex"
        "ClearChannelRadioDigital.iHeartRadio"
        "D52A8D61.FarmVille2CountryEscape"
        "D5EA27B7.Duolingo-LearnLanguagesforFree"
        "DB6EA5DB.CyberLinkMediaSuiteEssentials"
        "DolbyLaboratories.DolbyAccess"
        "DolbyLaboratories.DolbyAccess"
        "Drawboard.DrawboardPDF"
        "Facebook.Facebook"
        "Fitbit.FitbitCoach"
        "Flipboard.Flipboard"
        "GAMELOFTSA.Asphalt8Airborne"
        "KeeperSecurityInc.Keeper"
        "NORDCURRENT.COOKINGFEVER"
        "PandoraMediaInc.29680B314EFC2"
        "Playtika.CaesarsSlotsFreeCasino"
        "ShazamEntertainmentLtd.Shazam"
        "SlingTVLLC.SlingTV"
        "SpotifyAB.SpotifyMusic"
        "TheNewYorkTimes.NYTCrossword"
        "ThumbmunkeysLtd.PhototasticCollage"
        "TuneIn.TuneInRadio"
        "WinZipComputing.WinZipUniversal"
        "XINGAG.XING"
        "flaregamesGmbH.RoyalRevolt2"
        "king.com.*"
        "king.com.BubbleWitch3Saga"
        "king.com.CandyCrushSaga"
        "king.com.CandyCrushSodaSaga"
    )

    Write-DebloatLog -Message "Getting list of currently installed packages..." -Type Info

    # Get currently installed packages
    try {
        $allBloat = Get-AppxPackage -AllUsers | Select-Object -Property Name
    }
    catch {
        Write-DebloatLog -Message "Error getting installed packages: $_" -Type Error
        $allBloat = @()
    }

    # Filter grid with Standard Catalog before showing to user
    $MergedBlw = @()
    foreach ($blw in $allBloat.Name) {
        if ($Bloatware -icontains $blw) {
            Write-DebloatLog -Message "$blw was already in standard removal list" -Type Info
        }
        else {
            $MergedBlw += $blw
        }
    }

    # Show dialog to let user choose additional bloatware
    $boxreturn = Show-MessageBox -Title "Windows 11 Debloat" -Text "Do you want to manually select additional bloatware to remove?`n`nNOTE: A standard set of bloatware will be removed automatically." -Style Question -Buttons Yes_No -Topmost -NumericReturn

    if ($boxreturn -eq 6) { # User clicked Yes
        try {
            $choosenapps = Show-EnhancedGridView -InputObject ($MergedBlw | ForEach-Object { [PSCustomObject]@{ Name = $_ } } | Sort-Object Name) -Title "Select Additional Bloatware to Remove (Hold Ctrl to select multiple)" -PassThru
        }
        catch {
            Write-DebloatLog -Message "Error displaying selection grid: $_" -Type Error
            $choosenapps = $null
        }
    }

    # Add user-selected apps to bloatware list
    if ($choosenapps) {
        foreach ($app in $choosenapps) {
            $appName = $app.Name
            if ($Bloatware -icontains $appName) {
                Write-DebloatLog -Message "Selected bloatware '$appName' is already in standard removal list" -Type Info
            }
            else {
                $Bloatware += $appName
                Write-DebloatLog -Message "Added '$appName' to removal list" -Type Info
            }
        }
    }

    # Statistics
    Write-DebloatLog -Message "Standard bloatware list count: $($Bloatware.Count)" -Type Info
    Write-DebloatLog -Message "Installed packages count: $($allBloat.Count)" -Type Info
    Write-DebloatLog -Message "Additional packages available for removal: $($MergedBlw.Count)" -Type Info
    Write-DebloatLog -Message "Starting bloatware removal process..." -Type Info

    # Track removal progress
    $totalApps = $Bloatware.Count
    $currentApp = 0
    $successCount = 0
    $failureCount = 0

    # Remove selected bloatware
    foreach ($Bloat in $Bloatware) {
        $currentApp++
        Write-DebloatLog -Message "[$currentApp/$totalApps] Removing: $Bloat" -Type Info

        # Try removing the package with verification
        $result = Remove-AppxPackageSafely -PackageName $Bloat

        if ($result) {
            $successCount++
        }
        else {
            $failureCount++
        }

        # Small delay to prevent overwhelming system
        Start-Sleep -Milliseconds 500
    }

    # Summary of package removal
    Write-DebloatLog -Message "Bloatware removal complete" -Type Success
    Write-DebloatLog -Message "Successfully processed: $successCount packages" -Type Success
    if ($failureCount -gt 0) {
        Write-DebloatLog -Message "Failed to completely remove: $failureCount packages" -Type Warning
    }

    # Prevent apps from reinstalling
    Write-DebloatLog -Message "Setting registry keys to prevent apps from reinstalling..." -Type Info

$cdm = @(
    "ContentDeliveryAllowed"
    "FeatureManagementEnabled"
    "OemPreInstalledAppsEnabled"
    "PreInstalledAppsEnabled"
    "PreInstalledAppsEverEnabled"
    "SilentInstalledAppsEnabled"
    "SubscribedContent-314559Enabled"
    "SubscribedContent-338387Enabled"
    "SubscribedContent-338388Enabled"
    "SubscribedContent-338389Enabled"
    "SubscribedContent-338393Enabled"
    "SubscribedContentEnabled"
    "SystemPaneSuggestionsEnabled"
)

    $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    foreach ($key in $cdm) {
        Set-RegistryValueSafely -Path $cdmPath -Name $key -Value 0 -Type DWord
    }

    Set-RegistryValueSafely -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Value 2 -Type DWord
    Set-RegistryValueSafely -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord

###################################################
    # SERVICE TWEAKS                                  #
###################################################

    Write-DebloatLog -Message "Applying service tweaks..." -Type Info

    # Enable Windows Defender (if previously disabled)
    $WinDeff = Get-Item "HKLM:\Software\Policies\Microsoft\Windows Defender" -ErrorAction SilentlyContinue
    if ($WinDeff -and $WinDeff.Property -contains "DisableAntiSpyware") {
        try {
            Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
            Write-DebloatLog -Message "Re-enabled Windows Defender" -Type Success
        }
        catch {
            Write-DebloatLog -Message "Failed to re-enable Windows Defender: $_" -Type Error
        }
    }

# Disable Windows Update automatic restart
    Set-RegistryValueSafely -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Value 1 -Type DWord

# Stop and disable Home Groups services
    try {
        Stop-Service "HomeGroupListener" -Force -ErrorAction SilentlyContinue
Set-Service "HomeGroupListener" -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service "HomeGroupProvider" -Force -ErrorAction SilentlyContinue
Set-Service "HomeGroupProvider" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-DebloatLog -Message "Disabled Home Groups services" -Type Success
    }
    catch {
        Write-DebloatLog -Message "Failed to disable Home Groups services: $_" -Type Error
    }

###################################################
    # DISABLE ONEDRIVE                                #
###################################################

    Write-DebloatLog -Message "Disabling OneDrive..." -Type Info
    Set-RegistryValueSafely -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord

    # Ask for restart to apply changes
    Write-DebloatLog -Message "All tweaks have been applied!" -Type Success

    if ($global:ErrorOccurred) {
        Write-DebloatLog -Message "Some operations encountered warnings or errors. Check the log for details." -Type Warning
    }

    Write-DebloatLog -Message "Note: To customize Windows 11 UI (context menus, taskbar, explorer view, etc.), run the tweakW11.ps1 script in the gui-tweaks folder." -Type Info

    $bResult = Show-MessageBox -Text "Reboot $($env:COMPUTERNAME) to apply all changes?" -Title "Windows 11 Debloat - Restart Required" -Buttons Yes_No -Topmost -Style Question -NumericReturn
    if ($bResult -eq 6) {
        Write-DebloatLog -Message "User selected to restart computer" -Type Info
        Restart-Computer -Force
    }
    else {
        Write-DebloatLog -Message "User selected not to restart computer" -Type Info
        Write-DebloatLog -Message "Some changes may not take effect until the system is restarted" -Type Warning
    }
}
catch {
    Write-DebloatLog -Message "A critical error occurred during script execution: $_" -Type Error
    Show-MessageBox -Text "A critical error occurred during script execution.`n`nError: $_" -Title "Windows 11 Debloat - Error" -Buttons OKOnly -Style Stop -Topmost
}

Write-DebloatLog -Message "Script execution complete" -Type Success


