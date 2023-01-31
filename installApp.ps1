#Make Temp Directory
mkdir C:\Temp
# Install Chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Use Chocolatey to install applications
choco install googlechrome
choco install adobereader

iwr -useb https://dl3.checkpoint.com/paid/65/659c7e29b747761466a37ed4880667a5/E86.50_CheckPointVPN.msi?HashKey=1673509847_ad5bce3164570226f8d38fd2562f1f20&xtn=.msi -outfile C:\Temp\Checkpoint.msi
msiexec.exe /i C:\Temp\Checkpoint.msi /quiet 
