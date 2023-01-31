 $text4shell = Get-Childitem -Path C:\ -Include *commons*text* -Recurse -ErrorAction SilentlyContinue
 write-output $text4shell | Export-Csv -Path "C:\Temp\text4shell-%computername%.csv"