$start_time = Get-Date
Write-Output $start_time
#Invoke-WebRequest -Uri $url -OutFile $output
#Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\ninja.msi /quiet'
# Start-Process -FilePath ".\ninja.msi" -waitsx



$serverName = ""
$serverIP = ""
$vpnName = ""
$hostFile = "$env:windir\System32\drivers\etc\hosts"
"$serverIP $serverName" | Add-Content -PassThru $hostFile
Add-VpnConnection -Name $vpnName -ServerAddress "$serverName" -TunnelType "Sstp" -EncryptionLevel "Required" -AuthenticationMethod Eap -SplitTunneling -AllUserConnection -RememberCredential -PassThru

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install adobereader -y -v
choco install googlechrome -y -v
choco install firefox -y -v
choco install 7zip -y -v
choco install jre8 -y -v
choco install vlc -y -v
choco install vscode -y -v
choco install snagit -y -v
