Invoke-WebRequest https://downloadmirror.intel.com/30279/a08/WiFi_22.40.0_Driver64_Win10.exe -OutFile 'c:\windows\temp\installer.exe' -UseBasicParsing
Invoke-Command -ScriptBlock {
    c:\windows\temp\installer.exe /silent
}
