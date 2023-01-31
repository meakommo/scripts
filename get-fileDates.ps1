Get-ChildItem C:\Users -Recurse | Select-Object -Property Name, CreationTime |  Sort-Object CreationTime -Descending
