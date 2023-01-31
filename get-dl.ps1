$Result=@()
$groups = Get-DistributionGroup -ResultSize Unlimited
$totalmbx = $groups.Count
$i = 1
$PercentComplete = 0
$CurrentItem = 0
$groups | ForEach-Object {
    $group = $_
    Get-DistributionGroupMember -Identity $group.Name -ResultSize Unlimited | ForEach-Object {
        $member = $_
        $Result += New-Object PSObject -property @{
            GroupName = $group.DisplayName
            Member = $member.Name
            EmailAddress = $member.PrimarySMTPAddress
            RecipientType= $member.RecipientType
            
        }}
    Write-Progress -activity "Processing $_" -Status "$PercentComplete% Complete:" -PercentComplete $PercentComplete
    $CurrentItem++
    $PercentComplete = [int](($CurrentItem / $totalmbx) * 100)
}
$Result | Export-CSV "C:\Temp\All-Distribution-Group-Members.csv"