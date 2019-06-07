# cleanup.ps1
# Created 2/14/2019
# Cleans up the C:\Windows10UpgradeDiags folder

$SaveDir = "$env:HOMEDRIVE\Windows10UpgradeDiags"
Remove-Item $SaveDir -Recurse -Force -ErrorAction SilentlyContinue