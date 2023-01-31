$mailboxes = Get-Mailbox -ResultSize unlimited | where{$_.RecipientTypeDetails -ne "DiscoveryMailbox"}  
  
$Result = foreach ($mailbox in $mailboxes){
    Write-Output $mailbox
    Get-MailboxPermission -Identity $mailbox.UserPrincipalName  
}

$Result | Export-CSV "C:\Temp\ALL-Calendars.csv"
