Set-ExecutionPolicy RemoteSigned
Install-PackageProvider -Name NuGet -force
Install-Module PSWindowsUpdate -Force
Import-Module PSWindowsUpdate
Get-WindowsUpdate -AcceptAll -Install