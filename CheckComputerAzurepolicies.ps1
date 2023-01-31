#This script first imports the required modules (AzureAD and MSOnline) and then establishes a connection to Azure AD and Microsoft 365.
#It then gets the computer object for the current computer and retrieves the list of all device policies in the tenant.
#Next, it filters the list of policies to only include those that are applied to the current computer. Finally, it prints the names of the applied policies.
#Note that this script requires that you have the Azure AD and Microsoft 365 PowerShell modules installed and that you have the necessary permissions
# to connect to Azure AD and Microsoft 365.


# Import the required modules
Import-Module AzureAD
Import-Module MSOnline

# Connect to Azure AD and Microsoft 365
Connect-AzureAD
Connect-MsolService

# Get the computer object
$computer = Get-MsolComputer -ComputerName $env:COMPUTERNAME

# Get the list of policies applied to the computer
$policies = Get-MsolPolicy -PolicyType Device

# Filter the list of policies to only include those that are applied to the computer
$appliedPolicies = $policies | Where-Object {$computer.AppliedPolicies -contains $_.ObjectId}

# Print the names of the applied policies
$appliedPolicies | Select-Object -ExpandProperty DisplayName

