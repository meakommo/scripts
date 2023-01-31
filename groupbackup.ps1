#Get the UserName of the user in question
write-output "Enter the Username"
$UserName = read-host
# Connect to Azure AD
Connect-AzureAD 

# Get user and their group memberships
$user = Get-AzureADUser -SearchString $UserName
$userObject = $user.ObjectId
Get-AzureADUserMembership -ObjectId $userObject | export-CSV C:\temp\$UserName.csv 

