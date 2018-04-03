$OSArch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
if ($OSArch -eq "64-bit"){
    $args = "/i googlechromestandaloneenterprise64.msi","/q"
    Start-Process msiexec.exe -ArgumentList $args -Wait
} else {
    $args = "/i googlechromestandaloneenterprise.msi","/q"
    Start-Process msiexec.exe -ArgumentList $args -Wait
}