$testOnly = $false #if True no change will be mah

$o365Username = "admin@xenithconsulting.onmicrosoft.com"
$O365passwordFilePath = "C:\ad-scripts\Creds\ad.adminBNESVC01-O365Cred.txt"
#### To update the password run the following 2 commands #########
#$credential = Get-Credential
#$credential.Password | ConvertFrom-SecureString | Out-File $O365passwordFilePath

$projectsSecGroupOU = "xenith.local/XEN Groups/Security Groups/Projects Folder"

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://bnesvc01.xenith.local/PowerShell/
Import-PSSession $Session

############## Get Directory and Project Name #####################

Function Get-Folder($initialDirectory="P:")

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select the project folder"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}


$projectFolder = Get-Folder
$folderName = Split-Path $projectFolder -Leaf
$projectName = $folderName.Split(' ')[0]
$groupName = "Projects - " + $projectName + " Admins"

############## Get users #####################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "$projectName - Select users"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(125,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(200,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(380,20)
$label.Text = "Enter the name of the users who need to access the project $projectName :"
$form.Controls.Add($label)



$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(360,20)
$form.Controls.Add($textBox)

$form.Topmost = $true

$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $groupMembersString = $textBox.Text
    $groupMembersString
    $groupMembersString = $groupMembersString.Replace(' and ', ', ')
    $groupMembersString = $groupMembersString.Replace('Xenith Admins', ', ')
    $groupMembers = $groupMembersString.Split(',')
    $usersArray = @()
    foreach ($member in $groupMembers) {
        if (($member.Trim()).length -gt 0) {
            $userFilter = "(Name -like '*" + $member.Trim() + "*') -And (SamAccountName -notlike 'FT.*')"
            $user = New-Object -TypeName PSObject
            $user | Add-Member -Name 'Name' -MemberType Noteproperty -Value $member.Trim()

            if (!(Get-ADUser -Filter $userFilter)) {
                $user | Add-Member -Name 'InAD' -MemberType Noteproperty -Value $false
                $user | Add-Member -Name 'UPN' -MemberType Noteproperty -Value "Could not found user"
                $user | Add-Member -Name 'ToAdd' -MemberType Noteproperty -Value $false
            } else {
                $upn = (Get-ADUser -Filter $userFilter | select UserPrincipalName).UserPrincipalName
                $user | Add-Member -Name 'InAD' -MemberType Noteproperty -Value $true
                $user | Add-Member -Name 'UPN' -MemberType Noteproperty -Value $upn
                $user | Add-Member -Name 'ToAdd' -MemberType Noteproperty -Value $true

            }
            #Add-DistributionGroupMember -Identity $groupName  -Member $member.Trim()
            $usersArray += $user
        }
    }
    foreach ($user in $usersArray) {
        $user
    }

}


$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState


$handler_button1_Click=
{
    $listBox1.Items.Clear();
    $form1.Controls.remove($button1)

    if ($testOnly) {$listBox1.Items.Add("Testing mode (no change will be applied)")}

    if ($checkBoxCreateGroup.Checked) {
        $listBox1.Items.Add('Creating group: "' + $groupName + '"')
        $groupAlias = "Projects"+ $projectName + "Admins"
        if (!($testOnly)) {
            New-DistributionGroup -Name $groupName -Type "Security" -Alias $groupAlias -OrganizationalUnit $projectsSecGroupOU
        }

    }

    if ($checkBoxAddUsers.Checked) {
        $listBox1.Items.Add("Adding users:")
        Foreach ($checkBox in $checkBoxUser) {
            if ($checkBox.Checked) {
                $listBox1.Items.Add("    " + $checkBox.Text)
                if (!($testOnly)) {
                    Add-DistributionGroupMember -Identity $groupName  -Member $checkBox.Text
                }
            }

        }

    }

    if ($checkBoxSyncO365.Checked) {
        $listBox1.Items.Add("Sync Active directory with Azure (Office 365)")
        if (!($testOnly)) {
            Start-ADSyncSyncCycle -PolicyType Delta
        }
    }

    if ($checkBoxSyncADController.Checked) {
        $listBox1.Items.Add("Sync all the domain controllers (this may take a minute to complete)")
        if (!($testOnly)) {
            (Get-ADDomainController -Filter *).Name | Foreach-Object {repadmin /syncall $_ (Get-ADDomain).DistinguishedName /e /A | Out-Null}; Start-Sleep 10; Get-ADReplicationPartnerMetadata -Target "$env:userdnsdomain" -Scope Domain | Select-Object Server, LastReplicationSuccess
        }
    }

    if ($checkBoxSetNTFS.Checked) {
        $listBox1.Items.Add("Set Permissions on the project folder")
        if (!($testOnly)) {
            #Disable and convert inheritance
            $acl = Get-ACL -Path $projectFolder
            $acl.SetAccessRuleProtection($True, $True)
            Set-Acl -Path $projectFolder -AclObject $acl

            #Set Permissions
            $acl = Get-Acl $projectFolder
            $usersid = New-Object System.Security.Principal.Ntaccount ("XENITH\Xenith Users")
            $acl.PurgeAccessRules($usersid)
            $samAccountName = (Get-ADGroup -Filter {Name -eq $groupName}).SamAccountName
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("XENITH\$samAccountName","DeleteSubdirectoriesAndFiles, Modify, Synchronize","ContainerInherit, ObjectInherit","None","Allow")
            $acl.SetAccessRule($AccessRule)
            $AccessRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule("XENITH\Xenith Admins","FullControl","ContainerInherit, ObjectInherit","None","Allow")
            $acl.SetAccessRule($AccessRule2)
            $acl | Set-Acl $projectFolder

        }
    }
    Start-ADSyncSyncCycle -PolicyType Delta

    if ($checkBoxSetPublicFolder.Checked) {
        $listBox1.Items.Add("Setting permission on the public folder")
        Get-PSSession | Remove-PSSession
        $listBox1.Items.Add("     Connecting to Office 365")
        $o365Password = Get-Content $O365passwordFilePath | ConvertTo-SecureString
        $O365CREDS = new-object -typename System.Management.Automation.PSCredential -argumentlist $o365Username, $o365Password
        $SESSION = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365CREDS -Authentication Basic -AllowRedirection
        Import-PSSession $SESSION

        $listBox1.Items.Add("     Searching for the project folder in the Public Folders")
        $publicFolder = Get-PublicFolder -recurse -resultsize unlimited | where {$_.name –like $projectName}
        if ($publicFolder -eq $Null) {
            $listBox1.Items.Add("     Could not found the public folder")
        } else {
            $identity = $publicFolder.Identity
            $listBox1.Items.Add("     Public folder found: $identity")
            if (!($testOnly)) {
                Enable-MailPublicFolder $identity
            }
            $mailbox = Get-MailPublicFolder $identity
            $OldEmail = $mailbox.PrimarySMTPAddress
            $NewEmail = $OldEmail -Replace "xenithconsulting.onmicrosoft.com", "xenith.com.au"
            $listBox1.Items.Add("     Adding email address $NewEmail")
            Write-Host "Adding email address $NewEmail" -ForegroundColor Green
            if (!($testOnly)) {
                Set-MailPublicFolder $identity -EmailAddresses @{add=$NewEmail}
            }
            $listBox1.Items.Add("     Removing unnecessary permissions")
            Write-Host "Removing unnecessary permissions" -ForegroundColor Green
            if (!($testOnly)) {
                Remove-PublicFolderClientPermission -Identity $identity -User "Hannah Alkoby" -Confirm:$false -ErrorAction SilentlyContinue
                Remove-PublicFolderClientPermission -Identity $identity -User "Melinda Raisch" -Confirm:$false -ErrorAction SilentlyContinue
                Remove-PublicFolderClientPermission -Identity $identity -User "Xenith Users" -Confirm:$false -ErrorAction SilentlyContinue
                Remove-PublicFolderClientPermission -Identity $identity -User "Anonymous" -Confirm:$false -ErrorAction SilentlyContinue
            }

            $listBox1.Items.Add("     Checking if the security group synched to Office 365")
            $groupExists = $false
            $RetryCount = 0
            $RetryMax = 20

            do {

                $Retrycount = $RetryCount + 1
                if ($RetryCount -ge $RetryMax) {$groupExists = $true}

                $testCheckIfSynched = Get-DistributionGroup $groupName -ErrorAction SilentlyContinue
                If ($testCheckIfSynched -ne $Null) {
                    $groupExists = $true
                    $listBox1.Items.Add("     Setting permissions for $groupName")
                    Write-Host "Setting permissions for $groupName" -ForegroundColor Green
                    if (!($testOnly)) {
                        Add-PublicFolderClientPermission -Identity $identity -User $groupName -AccessRights PublishingEditor
                    }
                } else {
                    $groupExists = $false
                    $listBox1.Items.Add("     Waiting for the group to sync, retrying in 30s ( $Retrycount / $RetryMax ) ..." )
                    Write-Host "Waiting for security group to be synched, retrying in 30 seconds ( $Retrycount / $RetryMax ) ..." -ForegroundColor Cyan
                    Start-Sleep -Seconds 30
                }

            } While ($groupExists -eq $false)

            $listBox1.Items.Add("The public folder is now ready")
            Write-Host "The project folder is now ready, the permissions are set as follow" -ForegroundColor Green
            Get-PublicFolderClientPermission $identity | select Identity,User,AccessRights

        }

    }

    $listBox1.Items.Add("Script completed")
    $form1.Controls.remove($button1)

    #if ( !$checkBox1.Checked -and !$checkBox2.Checked -and !$checkBox3.Checked ) {   $listBox1.Items.Add("No CheckBox selected....")}
}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
    $form1.WindowState = $InitialFormWindowState
}

$form1 = New-Object System.Windows.Forms.Form
$form1.Text = 'Set Project Permissions: "' + $projectName + '"'
$form1.Name = "form1"
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 800
$System_Drawing_Size.Height = 600
$form1.ClientSize = $System_Drawing_Size

$button1 = New-Object System.Windows.Forms.Button
$button1.TabIndex = 4
$button1.Name = "button1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 75
$System_Drawing_Size.Height = 23
$button1.Size = $System_Drawing_Size
$button1.UseVisualStyleBackColor = $True
$button1.Text = "Run Script"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 556
$button1.Location = $System_Drawing_Point
$button1.DataBindings.DefaultDataSourceUpdateMode = 0
$button1.add_Click($handler_button1_Click)
$form1.Controls.Add($button1)

$listBox1 = New-Object System.Windows.Forms.ListBox
$listBox1.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 380
$System_Drawing_Size.Height = 500
$listBox1.Size = $System_Drawing_Size
$listBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$listBox1.Name = "listBox1"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 370
$System_Drawing_Point.Y = 13
$listBox1.Location = $System_Drawing_Point
$listBox1.TabIndex = 3
$form1.Controls.Add($listBox1)


#$label1 = New-Object System.Windows.Forms.Label
#$label1.Location = New-Object System.Drawing.Point(27,199)
#$label1.Size = New-Object System.Drawing.Size(320,369)
#$NL = "`r`n"
#$label1.Text = "If selected, the following users will be added to the group:" + $NL + $NL + $NL

$labelUsersFound = New-Object System.Windows.Forms.Label
$labelUsersFound.Location = New-Object System.Drawing.Point(27,220)
$labelUsersFound.Size = New-Object System.Drawing.Size(320,20)
$labelUsersFound.Text = "Select the users to add:"
$form1.Controls.Add($labelUsersFound)


$usersNotFound = New-Object System.Collections.ArrayList
$userNumber = 0
$locationY = 240
$checkBoxUser = New-Object System.Collections.ArrayList
foreach ($user in $usersArray) {

    if ($user.InAD) {
        $checkBoxUserItem = New-Object System.Windows.Forms.CheckBox
        $checkBoxUser.Add($checkBoxUserItem)
        #$checkBoxUser[$userNumber] = New-Object System.Windows.Forms.CheckBox
        $checkBoxUser[$userNumber].UseVisualStyleBackColor = $True
        $System_Drawing_Size = New-Object System.Drawing.Size
        $System_Drawing_Size.Width = 300
        $System_Drawing_Size.Height = 24
        $checkBoxUser[$userNumber].Size = $System_Drawing_Size
        $checkBoxUser[$userNumber].Text = $user.UPN
        $System_Drawing_Point = New-Object System.Drawing.Point
        $System_Drawing_Point.X = 35
        $System_Drawing_Point.Y = $locationY
        $checkBoxUser[$userNumber].Location = $System_Drawing_Point
        $checkBoxUser[$userNumber].DataBindings.DefaultDataSourceUpdateMode = 0
        $checkBoxUser[$userNumber].Name = "checkBoxUser($userNumber)"
        $checkBoxUser[$userNumber].Checked = $True
        $form1.Controls.Add($checkBoxUser[$userNumber])
        $userNumber ++
        $locationY = $locationY + 20
    } else {
        $usersNotFound.Add($user.Name)
    }
}

if ($usersNotFound.Count -gt 0) {
    $labelUsersNotFound = New-Object System.Windows.Forms.Label
    $labelUsersNotFound.Location = New-Object System.Drawing.Point(27,500)
    $labelUsersNotFound.Size = New-Object System.Drawing.Size(320,50)
    $labelUsersNotFound.Text = "The following users could not be found: " +($usersNotFound -join ",")
    $form1.Controls.Add($labelUsersNotFound)
}

$checkBoxSetPublicFolder = New-Object System.Windows.Forms.CheckBox
$checkBoxSetPublicFolder.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 24
$checkBoxSetPublicFolder.Size = $System_Drawing_Size
$checkBoxSetPublicFolder.TabIndex = 3
$checkBoxSetPublicFolder.Text = "Set permissions on the Public Folder in Office 365"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 185
$checkBoxSetPublicFolder.Location = $System_Drawing_Point
$checkBoxSetPublicFolder.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBoxSetPublicFolder.Name = "checkBoxSetPublicFolder"
$checkBoxSetPublicFolder.Checked = $True
$form1.Controls.Add($checkBoxSetPublicFolder)

$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(43,155)
$label2.Size = New-Object System.Drawing.Size(320,35)
$label2.Text = $projectFolder
$form1.Controls.Add($label2)


$checkBoxSetNTFS = New-Object System.Windows.Forms.CheckBox
$checkBoxSetNTFS.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 24
$checkBoxSetNTFS.Size = $System_Drawing_Size
$checkBoxSetNTFS.TabIndex = 3
$checkBoxSetNTFS.Text = "Set permissions on folder:"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 137
$checkBoxSetNTFS.Location = $System_Drawing_Point
$checkBoxSetNTFS.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBoxSetNTFS.Name = "checkBoxSetNTFS"
$checkBoxSetNTFS.Checked = $True
$form1.Controls.Add($checkBoxSetNTFS)

$checkBoxSyncO365 = New-Object System.Windows.Forms.CheckBox
$checkBoxSyncO365.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 24
$checkBoxSyncO365.Size = $System_Drawing_Size
$checkBoxSyncO365.TabIndex = 2
$checkBoxSyncO365.Text = "Sync with Office 365"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 106
$checkBoxSyncO365.Location = $System_Drawing_Point
$checkBoxSyncO365.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBoxSyncO365.Name = "checkBoxSyncO365"
$checkBoxSyncO365.Checked = $True
$form1.Controls.Add($checkBoxSyncO365)

$checkBoxSyncADController = New-Object System.Windows.Forms.CheckBox
$checkBoxSyncADController.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 24
$checkBoxSyncADController.Size = $System_Drawing_Size
$checkBoxSyncADController.TabIndex = 1
$checkBoxSyncADController.Text = "Sync with all the Domain Controllers"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 75
$checkBoxSyncADController.Location = $System_Drawing_Point
$checkBoxSyncADController.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBoxSyncADController.Name = "checkBoxSyncADController"
$checkBoxSyncADController.Checked = $True

$form1.Controls.Add($checkBoxSyncADController)

$checkBoxAddUsers = New-Object System.Windows.Forms.CheckBox
$checkBoxAddUsers.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 24
$checkBoxAddUsers.Size = $System_Drawing_Size
$checkBoxAddUsers.TabIndex = 0
$checkBoxAddUsers.Text = "Add the listed users to the group"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 44
$checkBoxAddUsers.Location = $System_Drawing_Point
$checkBoxAddUsers.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBoxAddUsers.Name = "checkBoxAddUsers"
$checkBoxAddUsers.Checked = $True
$form1.Controls.Add($checkBoxAddUsers)

$checkBoxCreateGroup = New-Object System.Windows.Forms.CheckBox
$checkBoxCreateGroup.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 300
$System_Drawing_Size.Height = 24
$checkBoxCreateGroup.Size = $System_Drawing_Size
$checkBoxCreateGroup.TabIndex = 0
$checkBoxCreateGroup.Text = "Create Group $groupName"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 13
$checkBoxCreateGroup.Location = $System_Drawing_Point
$checkBoxCreateGroup.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBoxCreateGroup.Name = "checkBoxCreateGroup"
$checkBoxCreateGroup.Checked = $True

$form1.Controls.Add($checkBoxCreateGroup)


#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form1.ShowDialog()| Out-Null

#$groupMembers.GetType()