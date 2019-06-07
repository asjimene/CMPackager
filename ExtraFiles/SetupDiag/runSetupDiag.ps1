# runSetupDiag.ps1
# Created 2/14/2019
# Runs SetupDiag and saves it to the folder C:\Windows10UpgradeDiags

$timestamp = Get-Date -Format o | ForEach-Object {$_ -replace ":", "."}
$SaveDir = "$env:HOMEDRIVE\Windows10UpgradeDiags\$timestamp"
New-Item -ItemType Directory -Path $SaveDir -ErrorAction SilentlyContinue
Start-Process .\SetupDiag.exe -ArgumentList "/Output:`"$SaveDir\SetupDiag.log`"" -Wait