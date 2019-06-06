# Install the version of bootcamp intended for this device
Start-Process msiexec.exe  -ArgumentList "/i `"Apple\BootCamp64.msi`" /qn /norestart TRANSFORMS=`"BootCamp.mst`" /L*V C:\ProgramData\BootCampInstaller.log" -Wait


# Copy the latest BootCamp Files to update to the latest BootCamp Control Panel etc. - Doing so allows you to pick the boot drive in the contol panel when an APFS drive is present
# You can obtain the latest BootCamp Files by doing the following:
# 1. Run the "GetLatestBootcamp.ps1" Script
# 2. Download the BootCampESD.pkg specified by that script
# 3. Extract the package using 7-Zip, then extract the payload file, then extract the WindowsSupport.dmg file
# 4. run the command: msiexec /a BootCamp64.msi TARGETDIR=C:\Temp\BootCampLatest from the Apple folder of the extracted WindowsSupport.dmg
# 5. Copy the contents of the BootCampLatest folder into the SCCMPackager\ExtraFiles\AppleBootCamp\BootCampLatest folder
# 6. Uncomment the lines below
# 7. Run the SCCMPackager tool and package the bootcamp drivers

#Copy-Item ".\BootCampLatest\Program Files\Boot Camp\*" -Destination "C:\Program Files\Boot Camp" -Force -Recurse -ErrorAction SilentlyContinue
#Copy-Item ".\BootCampLatest\system32\AppleControlPanel.exe" -Destination "C:\Windows\System32\AppleControlPanel.exe" -Force -ErrorAction SilentlyContinue
#Copy-Item ".\BootCampLatest\system32\AppleOSSMgr.exe" -Destination "C:\Windows\System32\AppleOSSMgr.exe" -Force -ErrorAction SilentlyContinue