$WSInstallArgs = "/i","wireshark.msi","/qn"
Start-Process msiexec.exe -ArgumentList $WSInstallArgs -Wait

# Download WinPCap from https://www.winpcap.org/install/default.htm, place it in this folder and uncomment the line below to also install WinPCap
$PCapInstallArgs = "/S"
Start-Process ".\winpcap-nmap-4.13.exe" -ArgumentList $PCapInstallArgs -Wait

netsh advfirewall firewall add rule name="Remote Packet Capture Deamon (Wireshark)" dir=in action=allow program="C:\Program Files\WinPcap\rpcapd.exe" enable=yes profile=domain