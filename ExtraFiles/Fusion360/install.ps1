if (get-item "C:\Program Files\Autodesk\webdeploy\production\*\Fusion360.exe" -erroraction SilentlyContinue) {
    Write-Output "Upgrade"
    & ".\Fusion 360 Admin Install.exe" --process upgrade --quiet
}
else {
    Write-Output "Fresh Install"
    & ".\Fusion 360 Admin Install.exe" --quiet
}


for ($Timer = 0; ($Timer -lt 60) -and (Get-Process "Fusion*360*"); $Timer++) {
    Start-Sleep 5
}

# Create Version File
Remove-Item "C:\Program Files\Autodesk\Fusion360.json" -Force -ErrorAction SilentlyContinue
& ".\Fusion 360 Admin Install.exe" --process query --infofile "C:\Program Files\Autodesk\Fusion360.json" --quiet

for ($Timer = 0; ($Timer -lt 60) -and (Get-Process "Fusion*360*"); $Timer++) {
    Start-Sleep 5
}