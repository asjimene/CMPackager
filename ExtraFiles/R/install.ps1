Start-process Rinstall.exe -ArgumentList "/Silent" -wait

$FullVersion = (Get-Item RInstall.exe).VersionInfo.FileVersion
$Version = ($FullVersion.split('.'))[0..2] -join '.'
$PathToR = "C:\Program Files\R\R-$Version"
$PathToRexe = "$PathToR\bin\R.exe"

for ($i=0; $i -le 120; $i++){
    if (Test-Path $PathToRexe){
        sleep 10
        break
    }
    sleep 1
}

# NOTE: ENSURE THE 7za executable is in this folder
Start-Process 7za.exe -ArgumentList "x .\library.7z -o`"$PathToR`" -y" -wait
