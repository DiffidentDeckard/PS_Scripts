
# Import necessary assemblies to hide the window
Add-Type -AssemblyName System.Windows.Forms
Add-Type -Name ConsoleUtils -Namespace WPIA -MemberDefinition @'
   [DllImport("Kernel32.dll")]
   public static extern IntPtr GetConsoleWindow();
   [DllImport("user32.dll")]
   public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'@

# Hide Powershell window
$hWnd = [WPIA.ConsoleUtils]::GetConsoleWindow()
[WPIA.ConsoleUtils]::ShowWindow($hWnd, 0)

# Get the script shell
Clear-Host
$ws = New-Object -com "Wscript.Shell"

# Run this forever
while ($true)
{
  # Press F13 key
  $ws.sendkeys("{F13}")
  
  # Sleep
  Sleep -Seconds 60
}

# To get this to run on startup:
# 1. Press Windows Key + R
# 2. Type in shell:startup
# 3. Add a shortcut to this script in that directory
# 4. In the Target, type in:
#    %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -WindowStyle hidden -File "<ScriptDirectory>\PressButtonKeepScreenFromLocking.ps1"