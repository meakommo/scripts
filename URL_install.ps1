$URL = Read-Host -Prompt
Invoke-WebRequest $URL -OutFile 'c:\windows\temp\installer.exe' -UseBasicParsing
Invoke-Command  -ScriptBlock {
    c:\windows\temp\installer.exe /silent
}
