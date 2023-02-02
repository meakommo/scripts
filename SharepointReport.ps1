# Import the SharePoint Online module
Import-Module Microsoft.Online.SharePoint.PowerShell

# Set SharePoint Online admin URL
$ServiceURL ="https://anindilyakwalandcouncil-admin.sharepoint.com/"


Connect-SPOService -Url $ServiceURL

# Set path to store the report
$Path = "C:\Temp\GroupsReport.csv"

# Get all SharePoint Online site collections
$SiteCollections = Get-SPOSite -Limit All

# Initialize an array to store group information
$GroupsData = @()

# Iterate through all site collections
ForEach ($Site in $SiteCollections) {
    # Set SharePoint Online site URL
    $URL = $Site.Url

    # Get SharePoint Online groups for the current site collection
    $SiteGroups = Get-SPOSiteGroup -Site $URL

    # Iterate through the groups and collect information
    ForEach ($Group in $SiteGroups) {
        Write-Output $Group
        $GroupsData += New-Object PSObject -Property @{
            'Site URL' = $URL
            'Group Name' = $Group.Title
            'Permissions' = $Group.Roles -join ","
            'Users' = $Group.Users -join ","
        }
    }
}

# Export the data to CSV
$GroupsData | Export-Csv $Path -NoTypeInformation
