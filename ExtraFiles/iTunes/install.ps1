$OSArch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

If ($OSArch -eq "64-bit") {
    # Install iTunes 64-bit
    Start-Process msiexec.exe -ArgumentList "/i AppleApplicationSupport.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/i AppleApplicationSupport64.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/i AppleMobileDeviceSupport64.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/i AppleSoftwareUpdate.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/i Bonjour64.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/i iTunes64.msi /qn /norestart" -Wait
} 
Else {
    # Install iTunes 32-bit
    Start-Process msiexec.exe -ArgumentList "/i AppleApplicationSupport.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/i AppleMobileDeviceSupport.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/i AppleSoftwareUpdate.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/i Bonjour.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/i iTunes.msi /qn /norestart" -Wait
}