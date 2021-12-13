# Check if this script has already ran
IF (Test-Path -Path C:\temp\removeoffice.txt) {
EXIT
 } 
ELSE {
    #push a notification to advise user of what is happening
    [reflection.assembly]::loadwithpartialname('System.Windows.Forms')
    [reflection.assembly]::loadwithpartialname('System.Drawing')
    $notify = new-object system.windows.forms.notifyicon
    $notify.icon = [System.Drawing.SystemIcons]::Information
    $notify.visible = $true
    $notify.showballoontip(10,'ATLANTIC DIGITAL','Microsoft Office 2013 is being upgraded to Office 2019',[system.windows.forms.tooltipicon]::None)
    #remove an instances of Office
    Get-AppxPackage -name “Microsoft.Office.Desktop” | Remove-AppxPackage
    #create the test file
    New-Item -Path C:\temp -Name "removeoffice.txt" -ItemType "file" -Value "Office has Already been installed. For more information about this file refer to - GPO Deploy Office VLK 2019"
    #wait 15 minutes to allow time for removal
    Start-Sleep -s 900
    #ask User to restart but do not force it using a Push notification and Switch together
    $msgBoxInput =  [System.Windows.Forms.MessageBox]::Show('Your computer needs to be restarted to finish upgrading to Office 2019, would you like to restart now?','input','YesNo','Error')
        switch  ($msgBoxInput) {
        'Yes' {
            Restart-Computer
    }
        'No' {
            powershell -WindowStyle hidden -Command "& {[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Please restart your computer at the earliest convience to complete the upgrade','WARNING')}"
        }
  }
 }