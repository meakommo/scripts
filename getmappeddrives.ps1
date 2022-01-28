#Script Fetch and Drop
$script = Read-Host "Enter Script to download"
$downloadedscript = Invoke-WebRequest -URI https://raw.githubusercontent.com/meakommo/scripts/main/"$script"
New-Item -Path C:\temp -Name "$script.ps1" -ItemType "file" -Value "$downloadedscript"
