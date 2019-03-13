$OSArch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

If ($OSArch -eq "64-bit") {
    # Install iTunes 64-bit
    Start-Process msiexec.exe -ArgumentList "/x AppleApplicationSupport.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/x AppleApplicationSupport64.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/x AppleMobileDeviceSupport64.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/x AppleSoftwareUpdate.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/x Bonjour64.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/x iTunes64.msi /qn /norestart" -Wait
} 
Else {
    # Install iTunes 32-bit
    Start-Process msiexec.exe -ArgumentList "/x AppleApplicationSupport.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/x AppleMobileDeviceSupport.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/x AppleSoftwareUpdate.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/x Bonjour.msi /qn /norestart" -Wait
    Start-Process msiexec.exe -ArgumentList "/x iTunes.msi /qn /norestart" -Wait
}