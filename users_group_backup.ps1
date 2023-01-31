write-output "Enter the Username"
$UserName = read-host

Get-ADPrincipalGroupMembership $Username | Select-Object name, groupcategory, groupscope | export-CSV C:\temp\$UserName.csv 
