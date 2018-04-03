#Following steps are being used to uninstall the current version of Google Chrome
# https://social.technet.microsoft.com/Forums/en-US/7e3c5fd3-e41c-4a0c-88fd-90ec7520edde/how-can-i-uninstall-google-chrome-using-power-shell?forum=winserverpowershell
Write-host "Un-Installing the current version of Google Chrome from your machine..." 

$AppInfo = Get-WmiObject Win32_Product -Filter "Name Like 'Google Chrome'"

If ($AppInfo) 
{
    & ${env:WINDIR}\System32\msiexec /x $AppInfo.IdentifyingNumber /Quiet /Passive /NoRestart
} else {
    $Reg32Key = Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome" -name "Version" -ErrorAction SilentlyContinue

    $Ver32Path = $Reg32Key.Version

    If ($Ver32Path) 
    {
        & ${env:ProgramFiles}\Google\Chrome\Application\$Ver32Path\Installer\setup.exe --uninstall --multi-install --chrome --system-level --force-uninstall
    }

    $Reg64Key = Get-ItemProperty -path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome' -name "Version" -ErrorAction SilentlyContinue

    $Ver64Path = $Reg64Key.Version

    If ($Ver64Path) 
    {
        & ${env:ProgramFiles(x86)}\Google\Chrome\Application\$Ver64Path\Installer\setup.exe --uninstall --multi-install --chrome --system-level --force-uninstall
    }
}