# Set the path to the USB drive
$usbDrive = "F:"

# Set the path to the Windows PE image file
$peImage = "C:\WinPE_amd64.wim"

# Set the path to the Windows 10 install media
$win10Install = "D:\"

# Set the path to the scripts directory on the USB drive
$scriptsDir = "$usbDrive\scripts"

# Create the scripts directory on the USB drive
New-Item -ItemType Directory -Path $scriptsDir

# Copy the Windows PE image file to the USB drive
Copy-Item $peImage "$usbDrive\sources\boot.wim"

# Create the install.wim file
Dism /Export-Image /SourceImageFile:$win10Install\sources\install.esd /SourceIndex:1 /DestinationImageFile:$scriptsDir\install.wim

# Create the install.cmd script
"@echo off" | Out-File "$scriptsDir\install.cmd" -Encoding ASCII
"wpeinit" | Out-File "$scriptsDir\install.cmd" -Encoding ASCII -Append
"dism /apply-image /imagefile:install.wim /index:1 /applydir:C:\" | Out-File "$scriptsDir\install.cmd" -Encoding ASCII -Append
"bcdboot C:\Windows /s C:" | Out-File "$scriptsDir\install.cmd" -Encoding ASCII -Append
"exit" | Out-File "$scriptsDir\install.cmd" -Encoding ASCII -Append

# Create the boot.wim file
Dism /Export-Image /SourceImageFile:$scriptsDir\install.wim /SourceIndex:1 /DestinationImageFile:$scriptsDir\boot.wim

# Create the boot.cmd script
"@echo off" | Out-File "$scriptsDir\boot.cmd" -Encoding ASCII
"wpeinit" | Out-File "$scriptsDir\boot.cmd" -Encoding ASCII -Append
"dism /apply-image /imagefile:boot.wim /index:1 /applydir:C:\" | Out-File "$scriptsDir\boot.cmd" -Encoding ASCII -Append
"bcdboot C:\Windows /s C:" | Out-File "$scriptsDir\boot.cmd" -Encoding ASCII -Append
"exit" | Out-File "$scriptsDir\boot.cmd" -Encoding ASCII -Append

# Set the USB drive as the default boot device
bcdboot $usbDrive\windows /s $usbDrive

# Clean up
Remove-Item $scriptsDir\install.wim
