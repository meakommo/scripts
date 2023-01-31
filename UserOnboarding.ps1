#**********************************************************************************
#           Account Creation Application
#
# Does the following:
# - Creates an AD account in the selected OU
# - Creates the Home Drive
# - Adds the user to Security Groups specific to their Department/Location and Role if desired
# - Adds the address details in AD based on their Location
# - Creates an Exchange Online mailbox for the user
#
# *Will NOT run unless the required boxes are filled out* - This is because the Form boxes have a checkfortext function, this can be removed but I found having mandatory fields is much better.
#
#This tool still works as of 20/12/2022 however some parts of the code may be out dated/no longer needed. I have added notes and # where data needs updating. 
#I have put descriptions where I think they are helpful to quickly understand what each section is for. The form can be changed to suit whatever attributes you want, you just need to edit
#the CreateADUser and CreateEmailUser functions to use the updated form boxes.
#
#You can run the script immediately (Don't run it inside ISE as forms cause that to crash not long afterwards, just run it with powershell) and it will generate the form window for you to see
#and get an understanding of the layout before adding in your own data.
#**********************************************************************************

#Creates Exchange Connection and imports AD module
$exchangesession = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri http://EXCHANGESERVER/powershell #On prem Exchange Server for mailbox creation
Import-PSSession $exchangesession -AllowClobber
Import-Module ActiveDirectory

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
Add-Type -Assembly System.Web 

#Department Variables - Departments are used for specific security groups and also the AD Attribute
$Departments = @("","DEPARTMENT 1","DEPARTMENT 2","DEPARTMENT 3","DEPARTMENT 4")

#Address Locations - Used for AD Attributes and can be used for address specific security groups
$AddressNames = @("","ADDRESS1","ADDRESS2","ADDRESS3","ADDRESS4","ADDRESS5")

#Address Variables - These are just the specific attribute values for the address selected used to populate AD
$ADDRESS1 = @{ "City" = "CITY";"State" = "STATE"; "StreetAddress" = "STREET ADDRESS";"PostalCode" = "POSTCODE" }
$ADDRESS2 = @{ "City" = "CITY";"State" = "STATE"; "StreetAddress" = "STREET ADDRESS";"PostalCode" = "POSTCODE" }
$ADDRESS3 = @{ "City" = "CITY";"State" = "STATE"; "StreetAddress" = "STREET ADDRESS";"PostalCode" = "POSTCODE" }
$ADDRESS4 = @{ "City" = "CITY";"State" = "STATE"; "StreetAddress" = "STREET ADDRESS";"PostalCode" = "POSTCODE" }
$ADDRESS5 = @{ "City" = "CITY";"State" = "STATE"; "StreetAddress" = "STREET ADDRESS";"PostalCode" = "POSTCODE" }

#Security Group Variables - These are specifc security/distribution groups you want added to users based on Department. Default Groups are the groups every user gets regardless of role/department. 
#For example GROUPS1 could be HRGROUPS and then it would contain the Default Groups + HR specific groups such as Human Resources etc..
#Role Specific groups can be used for roles. I had this set up so anyone with a job title containing "Driver" gets groups only Drivers needed. Can expand on this greatly or not use at all.
$default_groups = @("SECURITY GROUP","SECURITY GROUP","SECURITY GROUP")
$Groups1 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Groups2 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Groups3 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Groups4 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Groups5 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Groups6 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Groups7 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Groups8 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Groups9 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Groups10 = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"
$Rolespecifcgroups = $default_groups+"SECURITY GROUP","SECURITY GROUP","SECURITY GROUP"

#Date Variables - Used for Expiry date for contractors
$Days = @("","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31")
$Months = @("","01","02","03","04","05","06","07","08","09","10","11","12")
$Years = @("","2023","2024","2025","2026","2027","2028","2029")

#Domain Properties
$objIPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
$strDNSDomain = $objIPProperties.DomainName.toLower()
$strDOmainDN= "DC=,DC=" #Localdomain goes here
$dc = "" # FQDN of Domain Controller goes here

#Password Generator - Can use this password Generator if you want or you can put in a static password. The form has a field for password that i have just used instead.
$length = 15
$numberOfNonAlphanumericCharacters = 6
$password = [Web.Security.Membership]::GeneratePassword($length,$numberOfNonAlphanumericCharacters)
#$password = 

#Generate Form Objects - Part of the form generation
function Add-Node { 
        param ( 
            $selectedNode, 
            $dname,
            $name
        ) 
        $newNode = new-object System.Windows.Forms.TreeNode  
        $newNode.Name = $dname 
        $newNode.Text = $name
        $selectedNode.Nodes.Add($newNode) | Out-Null 
        return $newNode 
} 
#Generate OU Objects - Edit the below values to specific AD groups you add users/Contractors to or you can remove those filters and all of your OU structure will generate instead.
function Get-NextLevel {
    param (
        $selectedNode,
        $dn,
        $name
   )
   
    $OUs = Get-ADObject -Filter {(ObjectClass -eq "organizationalUnit") -and (OU -eq "SPECIFIC USER OU") -or (OU -eq "SPECIFIC USER/CONTRACTOR OU")} -SearchScope Onelevel -SearchBase $dn 

    If ($OUs -eq $null) {
        $node = Add-Node $selectedNode $dn $name
    } Else {
        $node = Add-Node $selectedNode $dn $name
        
        $OUs | ForEach-Object {
            Get-NextLevel $node $_.distinguishedName $_.Name
        }
    }
}
#Builds the OU tree to display within the form. 
function Build-TreeView { 
    if ($treeNodes)  
    {  
          $treeview1.Nodes.remove($treeNodes) 
        $form.Refresh() 
    } 
    
    $treeNodes = New-Object System.Windows.Forms.TreeNode 
    $treeNodes.text = "COMPANY NAME Active Directory" #This just shows a name in the OU list. Can add the business name if you want.
    $treeNodes.Name = "" 
    $treeNodes.Tag = "root" 
    $treeView1.Nodes.Add($treeNodes) | Out-Null 
     
    $treeView1.add_AfterSelect({ 
        $textboxOU.Text = $this.SelectedNode.Name
    }) 
     
    #Generate Module nodes 
    $basename = "LOCALDOMAIN" #Local Domain goes here such as example.local
    $OUs = Get-NextLevel $treeNodes $strDomainDN $basename
    
    $treeNodes.Expand() 
} 

#This is the function that creates the AD User based off the text entered in the form fields. Can remove any values you don't want to include or swap/add attributes.
function CreateADUser {
    $new_first = $BoxFirstName.text;
    $new_last = $BoxLastName.text;
    $EmpID = $BoxEmployeeID.text;
    $Employeetype = $boxemployeetype.Text
    $new_username = $BoxUserName.Text 
    $new_password = $BoxPassword.text | ConvertTo-SecureString -AsPlainText -Force
    $department = $DropDownDepartment.SelectedItem
    $Addressname = $DropDownAddress.SelectedItem
    switch ($Addressname){
    "ADDRESS1"         {
                           $Addressdetails = $ADDRESS1
                           continue
                          }
    "ADDRESS2" {
                           $Addressdetails = $ADDRESS2
                           continue
                          }
    "ADDRESS3"            {
                           $Addressdetails = $ADDRESS3
                           continue
                          }
    "ADDRESS4"              {
                           $Addressdetails = $ADDRESS4
                           continue
                          }
    "ADDRESS5"           {
                           $Addressdetails = $ADDRESS5
                           continue
                          }
    }    
    $Phone = $Boxphone.text
    $jobtitle = $BoxJob.text
    $Manager = $BoxManager.text
    $new_OU = $textboxOU.text;
    $Name = $new_first + ' ' + $new_last
    $userprincipal = "$new_first.$new_last@EMAILDOMAIN.com.au" #Emaildomain needs adding
    $HomeDirectory = "HOMEDRIVE PATH\Homes\$new_username" #Location of home drive if used.
    $employeetype = $boxemployeetype.text

    New-ADuser @Addressdetails -Name $name -DisplayName $name -GivenName $new_first -Surname $new_last -Path $new_OU -EmailAddress $userprincipal -samAccountName $new_username -UserPrincipalName $userprincipal -mobilephone $Phone -Department $department -Title $Jobtitle -Description $jobtitle -Manager $Manager -HomeDrive "H:" -HomeDirectory $homedirectory -accountPassword $new_password -Changepasswordatlogon $true -Enabled $true -Server $dc -ErrorAction Stop
        
        IF ($employeetype -eq 'Contractor'){
        $dateOfExpiration = get-date -year $DropdownYear.selecteditem -month $DropdownMonth.selecteditem -day $DropdownDay.selecteditem
        Set-ADAccountExpiration -Identity $new_username -DateTime $dateOfExpiration -Server $dc
        Set-ADuser -identity $new_username -replace @{'employeeType' = $employeetype} -Server $dc
            }

#This can be removed if you don't want to use it. Just adds the Employee ID if the field EmpID isn't <not set> which is auto applied when the contractor button is ticked
        IF ($empID -ne '<not set>'){
                Set-ADuser -identity $new_username -EmployeeID $empID -Server $dc 
                }

# This is where the address specific security groups are added. Printers or office distribtuion groups for example.
        IF ($Addressdetails -eq $ADDRESS1){
            Add-ADGroupMember -Identity 'ADDRESS1 SPECIFIC SECURITY GROUP' -Members $new_username
        }
        elseif ($Addressdetails -eq $ADDRESS2){
            Add-ADGroupMember -Identity 'ADDRESS2 SPECIFIC SECURITY GROUP' -Members $new_username
        }
        elseif ($Addressdetails -eq $ADDRESS3){
            Add-ADGroupMember -Identity 'ADDRESS3 SPECIFIC SECURITY GROUP' -Members $new_username
        }
        elseif ($Addressdetails -eq $ADDRESS4){
            Add-ADGroupMember -Identity 'ADDRESS4 SPECIFIC SECURITY GROUP' -Members $new_username
        }
    
    $MsgBox.Appendtext("*User placed in $new_ou`r`n")
    $MsgBox.Appendtext("*`r`n")
    $MsgBox.Appendtext("*H: Drive to $homedirectory`r`n")
    $MsgBox.Appendtext("*`r`n")
    $MsgBox.Appendtext("*User Created`r`n`r`n")
}

#This just checks the manager sam name exists and if it doesn't it stops the script, allowing you to fix the spelling and re-run.
function CheckManager {
    $managerusername = $BoxManager.text
    $managercheck = get-aduser $managerusername -ErrorAction SilentlyContinue
        IF ($managercheck -eq $null){
            $MsgBox.text = "MANAGER NOT FOUND - Please Fix`r`n`r`n"
            Exit
            }            
}

#Creates the mailbox. We use O365 so this creates a remote mailbox but can be changed to a regular mailbox if you do not use O365
function CreateEmailUser {

    $new_first = $BoxFirstName.text;
    $new_last = $BoxLastName.text;
    $new_username = $new_first + "." + $new_last;
    $Name = "$new_first $New_last"
    $MsgBox.Appendtext("*Creating Email for $name`r`n")
    $userprincipal = $new_username + "@.com.au"                  #Email domain goes here
    $routeaddress = $new_username + "@.mail.onmicrosoft.com"     #O365 Email Domain here
    $NewEmailuser = Enable-RemoteMailbox -Identity $userprincipal -RemoteRoutingAddress $routeaddress -DomainController $dc
    if ($newEmailUser -eq $NULL) {
            $MsgBox.Appendtext("Email Creation FAILED.`r`n`r`n")
        } else {
            $MsgBox.Appendtext("Mailbox created Successfully`r`n`r`n")
        }

}

#This function maps groups to departments. So you can have groups that are specific to HR for example assigned to new users with HR as their department.
function AddGroups {
    $new_first = $BoxFirstName.text;
    $new_last = $BoxLastName.text;
    $new_username = $BoxUserName.Text;
    $department = $DropDownDepartment.SelectedItem
    $jobtitle = $BoxJob.text
    $MsgBox.Appendtext("*Adding User to Security Groups`r`n")
#First line below is used to add users to role specific groups such as the "Drivers" example i gave in the Groups section above. Can use, expand on this or remove it if you don't want it.
#If the role doesn't exist it just moves on to groups specific to department. Example would be ($Department -match "Human Resources") {$HRGroups} and $HRGroups would be one of the groups in the 
#groups section near the top.
    $Groups = if ($jobtitle -like "*ROLENAME*" -or $jobtitle -like "*ROLENAME*") {$Rolespecificgroups} 
          elseif ($Department -match "Department1") {$Groups1} 
          elseif ($Department -match "Department2") {$Groups2} 
          elseif ($Department -match "Department3") {$Groups3} 
          elseif ($Department -match "Department4") {$Groups4} 
          elseif ($Department -match "Department5") {$Groups5} 
          elseif ($Department -match "Department6") {$Groups6} 
          elseif ($Department -match "Department7") {$Groups7} 
          elseif ($Department -match "Department8") {$Groups8} 
          elseif ($Department -match "Department9") {$Groups9} 
          elseif ($Department -match "Department10") {$Groups10} 
          else {$default_groups}
    
    foreach ($group_member in $Groups) {
        Add-ADGroupMember -Identity $group_member -Members $new_username -Server $dc
    }

}

#Sets the Home Drive and all the correct permissions. Can be removed if you don't use home drives or don't want this. Just remove the function call in the Start-Process function below.
function HomeDriveSetup {
$new_first = $BoxFirstName.text;
$new_last = $BoxLastName.text;
$new_username = $BoxUserName.Text;
$HomeDirectory = "\\HOMEDRIVEPATH\Homes\$new_username" #Home drive path if this is used

NEW-ITEM –path $HomeDirectory -type directory -force 

# Build Access Rule from parameters
$HomeFolderACL = Get-ACL -path $HomeDirectory
$AccessRule = NEW-OBJECT System.Security.AccessControl.FileSystemAccessRule($new_username,'FullControl','ContainerInherit, ObjectInherit','None','Allow')
$HomeFolderACL.AddAccessRule($AccessRule)
$HomeFolderACL | Set-ACL

}

#This starts the process and is executed when the Create User button is clicked. Checks the manager is correct first, if true it continues otherwise it stops, creates the AD User and waits 5 seconds
#to ensure any syncs have occured, adds the adgroups, creates the home drive (If used) and finally creates the mailbox.
function Start_process {
$MsgBox.text = "New Account Creation Process Started`r`n`r`n"
CheckManager
CreateADUser
$MsgBox.Appendtext("Waiting 5 seconds before continuing..`r`n")
$MsgBox.Appendtext("[5.")
Start-Sleep -m 1000
$MsgBox.Appendtext("4.")
Start-Sleep -m 1000
$MsgBox.Appendtext("3.")
Start-Sleep -m 1000
$MsgBox.Appendtext("2.")
Start-Sleep -m 1000
$MsgBox.Appendtext("1.")
Start-Sleep -m 1000
$MsgBox.Appendtext("0]`r`n")
$MsgBox.Appendtext("*Applying Group Memberships`r`n")
#Calls the AddGroups Functions
AddGroups
#Creates the Home Drive and Sets Permissions
$MsgBox.Appendtext("*Creating Home Drive and setting Permissions`r`n")
Homedrivesetup
#Calls the CreateEmailUser Functions
CreateEmailUser

$MsgBox.Appendtext("Account creation Process Complete`r`n`r`n")


}

#This is the functions responsible for mandating fields before enabling the Create User button. Can change to suit
function Checkfortext {
	if ($TextboxOU.Text.Length -ne 0 -and 
        $DropDownDepartment.Text.Length -ne 0 -and 
        $DropDownAddress.text.Length -ne 0 -and 
        $BoxFirstName.text.Length -ne 0 -and 
        $BoxLastName.text.Length -ne 0 -and 
        $BoxManager.text.Length -ne 0 -and 
        $BoxEmployeeID.text.Length -ne 0)
	{
		$Button.Enabled = $true
	}
	else
	{
		$Button.Enabled = $false
	}
}

#THis just closes the form if you click the X button
$button1_OnClick=  
{ 
$form1.Close() 
     
} 
     
$OnLoadForm_StateCorrection= 
{Build-TreeView 
} 
     
#--------------------
#Generating Form Code
#--------------------

$fontBoldLog = new-object System.Drawing.Font("Calibri",10,[Drawing.FontStyle]'Bold' ) #Font style for the bold text in the right side window
$fontBoldSize = new-object System.Drawing.Font("Calibri",9,[Drawing.FontStyle]'Bold' ) #Font for the Bold Labels
     
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(855,660) #This controls the size of the full form window
$Form.Text = "Account Manager - Create Account" #This is the name of the Window
$Form.FormBorderStyle = 'Fixed3D' 
$Form.MaximizeBox = $False
$Form.SizeGripStyle = "Hide"
$form.StartPosition = 'CenterScreen' #Controls where the form appears initially

$Label = New-Object System.Windows.Forms.Label
$Label.Location = New-Object System.Drawing.Size(10,5)
$Label.Size = New-Object System.Drawing.Size(400,20)
$Label.Text = "Please Enter User Details - Mandatory Fields are Bold"
$Form.Controls.Add($Label)

#All of the below code is named accordingly and should be easily understandable as to what it does. Labels are the names and Boxes are the text boxes. 
#You can add more boxes if you want, change existing boxes or remove them to suit. If you add new labels/boxes just copy the code from another label and box and edit.
#The Checkfortext function is added to the object to continously check text exists in the box. Any fields you want to mandate needs this line added.

$LabelFirstName = New-Object System.Windows.Forms.Label
$LabelFirstName.Location = New-Object System.Drawing.Size(10,37) #Location of the Label within the form window. Can change these values to move fields or when adding fields etc..
$LabelFirstName.Size = New-Object System.Drawing.Size(65,20) #Size of the box
$LabelFirstName.Text = "First Name:"
$LabelFirstName.Font = $fontBoldSize
$Form.Controls.Add($LabelFirstName)

$BoxFirstName = New-Object System.Windows.Forms.TextBox 
$BoxFirstName.Location = New-Object System.Drawing.Size(80,35) 
$BoxFirstName.Size = New-Object System.Drawing.Size(156,20) 
$Form.Controls.Add($BoxFirstName)
$BoxFirstName.add_TextChanged({ Checkfortext })

$LabelLastName = New-Object System.Windows.Forms.Label
$LabelLastName.Location = New-Object System.Drawing.Size(270,37)
$LabelLastName.Size = New-Object System.Drawing.Size(65,20)
$LabelLastName.Text = "Last Name:"
$LabelLastName.Font = $fontBoldSize
$Form.Controls.Add($LabelLastName)

$BoxLastName = New-Object System.Windows.Forms.TextBox 
$BoxLastName.Location = New-Object System.Drawing.Size(350,35) 
$BoxLastName.Size = New-Object System.Drawing.Size(145,20) 
$Form.Controls.Add($BoxLastName)
$BoxLastName.add_TextChanged({ Checkfortext })

$LabelUserName = New-Object System.Windows.Forms.Label
$LabelUserName.Location = New-Object System.Drawing.Size(10,67)
$LabelUserName.Size = New-Object System.Drawing.Size(65,20)
$LabelUserName.Font = $fontBoldSize
$LabelUserName.Text = "User Name:"
$Form.Controls.Add($LabelUserName)

#The username is automatically generated based on the first and last names. I couldn't find a way to do this when tabbing to this field, only works on clicks. Can remove this part or change it to suit.
$BoxUserName = New-Object System.Windows.Forms.TextBox 
$BoxUserName.Location = New-Object System.Drawing.Size(80,65) 
$BoxUserName.Size = New-Object System.Drawing.Size(156,20)
$Form.Controls.Add($BoxUserName)
$BoxUserName_OnClick = {
    if ($BoxFirstName.text -ne 0 -and
        $BoxLastName.text -ne 0)
    {
        $BoxUserName.text = $Boxfirstname.text + "." + $BoxLastname.text

    }
}
$BoxUserName.Add_Click($BoxUserName_OnClick)

$LabelEmployeeID = New-Object System.Windows.Forms.Label
$LabelEmployeeID.Location = New-Object System.Drawing.Size(270,67) 
$LabelEmployeeID.Size = New-Object System.Drawing.Size(75,20) 
$LabelEmployeeID.Font = $fontBoldSize
$LabelEmployeeID.Text = "Employee ID:"
$Form.Controls.Add($LabelEmployeeID)

$BoxEmployeeID = New-Object System.Windows.Forms.TextBox 
$BoxEmployeeID.Location = New-Object System.Drawing.Size(350,65) 
$BoxEmployeeID.Size = New-Object System.Drawing.Size(60,20) 
$Form.Controls.Add($BoxEmployeeID)
$BoxEmployeeID.add_TextChanged({ Checkfortext })

$LabelDepartment = New-Object System.Windows.Forms.Label
$LabelDepartment.Location = New-Object System.Drawing.Size(10,97) 
$LabelDepartment.Size = New-Object System.Drawing.Size(70,20)
$LabelDepartment.Font = $fontBoldSize
$LabelDepartment.Text = "Department:"
$Form.Controls.Add($LabelDepartment)

$DropDownDepartment = new-object System.Windows.Forms.ComboBox
$DropDownDepartment.Location = new-object System.Drawing.Size(80,95) 
$DropDownDepartment.Size = new-object System.Drawing.Size(156,20)

ForEach ($Items in $Departments) {
 $DropDownDepartment.Items.Add($Items) | Out-Null
}
$DropDownDepartment.SelectedItem = $DropDownDepartment.Items[0]
$Form.Controls.Add($DropDownDepartment)
$DropDownDepartment.add_TextChanged({ Checkfortext })

$LabelJob = New-Object System.Windows.Forms.Label
$LabelJob.Location = New-Object System.Drawing.Size(270,97)
$LabelJob.Size = New-Object System.Drawing.Size(65,20)
$LabelJob.Font = $fontBoldSize
$LabelJob.Text = "Job Title:"
$Form.Controls.Add($LabelJob)

$BoxJob = new-object System.Windows.Forms.Textbox
$BoxJob.Location = new-object System.Drawing.Size(350,95)
$BoxJob.Size = new-object System.Drawing.Size(145,20)
$Form.Controls.Add($BoxJob)

$LabelAddress = New-Object System.Windows.Forms.Label
$LabelAddress.Location = New-Object System.Drawing.Size(10,127) 
$LabelAddress.Size = New-Object System.Drawing.Size(66,20)
$LabelAddress.Font = $fontBoldSize
$LabelAddress.Text = "Address:"
$Form.Controls.Add($LabelAddress)

$DropDownAddress = new-object System.Windows.Forms.ComboBox
$DropDownAddress.Location = new-object System.Drawing.Size(80,125) 
$DropDownAddress.Size = new-object System.Drawing.Size(156,20)
ForEach ($Address in $AddressNames) {
 $DropDownAddress.Items.Add($Address) | Out-Null
}
$DropDownAddress.SelectedItem = $DropDownAddress.Items[0]
$Form.Controls.Add($DropDownAddress)
$DropDownAddress.add_TextChanged({ Checkfortext })

$LabelPhone = New-Object System.Windows.Forms.Label
$LabelPhone.Location = New-Object System.Drawing.Size(270,127)
$LabelPhone.Size = New-Object System.Drawing.Size(65,20)
$LabelPhone.Text = "Phone:"
$Form.Controls.Add($LabelPhone)

$BoxPhone = New-Object System.Windows.Forms.TextBox 
$BoxPhone.Location = New-Object System.Drawing.Size(350,125) 
$BoxPhone.Size = New-Object System.Drawing.Size(145,20) 
$BoxPhone.text = $Phone
$Form.Controls.Add($BoxPhone)

$LabelManager = New-Object System.Windows.Forms.Label
$LabelManager.Location = New-Object System.Drawing.Size(10,157) 
$LabelManager.Size = New-Object System.Drawing.Size(66,20)
$LabelManager.Font = $fontBoldSize
$LabelManager.Text = "Manager:"
$Form.Controls.Add($LabelManager)

$BoxManager = new-object System.Windows.Forms.Textbox
$BoxManager.Location = new-object System.Drawing.Size(80,155) 
$BoxManager.Size = new-object System.Drawing.Size(156,20)
$Form.Controls.Add($BoxManager)
$BoxManager.add_TextChanged({ Checkfortext })

$LabelPassword = New-Object System.Windows.Forms.Label
$LabelPassword.Location = New-Object System.Drawing.Size(270,157)
$LabelPassword.Size = New-Object System.Drawing.Size(65,20)
$LabelPassword.Font = $fontBoldSize
$LabelPassword.Text = "Password:"
$Form.Controls.Add($LabelPassword)

$BoxPassword = New-Object System.Windows.Forms.TextBox 
$BoxPassword.Location = New-Object System.Drawing.Size(350,155) 
$BoxPassword.Size = New-Object System.Drawing.Size(145,20) 
$BoxPassword.text = $password
$BoxPassword.PasswordChar='*'
$Form.Controls.Add($BoxPassword)

$LabelContractor = New-Object System.Windows.Forms.Label
$LabelContractor.Location = New-Object System.Drawing.Size(270,187)
$LabelContractor.Size = New-Object System.Drawing.Size(65,20)
$LabelContractor.Text = "Contractor:"
$Form.Controls.Add($LabelContractor)

#This sets some of the values when the box is checked and disables the employee ID field. Can customize/remove the values in the IF statement to suit.
$CheckBoxContractor = New-Object System.Windows.Forms.Checkbox 
$CheckBoxContractor.Location = New-Object System.Drawing.Size(350,185) 
$CheckBoxContractor.Size = New-Object System.Drawing.Size(20,20) 
$Form.Controls.Add($CheckBoxContractor)
$CheckboxContractor_OnClick = {
    if ($CheckboxContractor.Checked -eq $true)
    {
        $BoxEmployeeType.Enabled = $true 
        $DropdownDay.enabled = $true
        $Dropdownmonth.Enabled = $true
        $Dropdownyear.Enabled = $true
        $Boxemployeetype.Enabled = $false
        $Boxemployeetype.text = 'Contractor'
        $BoxemployeeID.text = '<not set>'
        $BoxemployeeID.Enabled = $false
    }
    elseif ($CheckboxContractor.Checked -eq $false)
    {
        $BoxEmployeeType.Enabled = $false
        $DropdownDay.enabled = $false
        $Dropdownmonth.Enabled = $false
        $Dropdownyear.Enabled = $false
        $Boxemployeetype.text = ""
        $BoxemployeeID.text = ""
        $BoxemployeeID.Enabled = $true
    }   
}
$CheckboxContractor.Add_Click($CheckboxContractor_OnClick)

$LabelEmployeeType = New-Object System.Windows.Forms.Label
$LabelEmployeeType.Location = New-Object System.Drawing.Size(270,215)
$LabelEmployeeType.Size = New-Object System.Drawing.Size(83,20)
$LabelEmployeeType.Text = "EmployeeType:"
$Form.Controls.Add($LabelEmployeeType)

$BoxEmployeeType = New-Object System.Windows.Forms.Textbox 
$BoxEmployeeType.Location = New-Object System.Drawing.Size(355,213) 
$BoxEmployeeType.Size = New-Object System.Drawing.Size(140,20) 
$BoxEmployeeType.Enabled = $false
$Form.Controls.Add($BoxEmployeeType)

$LabelDate = New-Object System.Windows.Forms.Label
$LabelDate.Location = New-Object System.Drawing.Size(270,240)
$LabelDate.Size = New-Object System.Drawing.Size(70,20)
$LabelDate.Text = "Expiry Date:"
$Form.Controls.Add($LabelDate)

$DropdownDay = New-Object System.Windows.Forms.ComboBox 
$DropdownDay.Location = New-Object System.Drawing.Size(355,238) 
$DropdownDay.Size = New-Object System.Drawing.Size(40,20) 
ForEach ($Day in $Days) {
 $DropdownDay.Items.Add($Day) | Out-Null
}
$DropdownDay.SelectedItem = $DropdownDay.Items[0]
$DropdownDay.Enabled = $False
$Form.Controls.Add($DropdownDay)

$DropdownMonth = New-Object System.Windows.Forms.ComboBox 
$DropdownMonth.Location = New-Object System.Drawing.Size(400,238) 
$DropdownMonth.Size = New-Object System.Drawing.Size(40,20) 
ForEach ($Month in $Months) {
 $DropdownMonth.Items.Add($Month) | Out-Null
}
$DropdownMonth.SelectedItem = $DropdownMonth.Items[0]
$DropdownMonth.Enabled = $False
$Form.Controls.Add($DropdownMonth)

$DropdownYear = New-Object System.Windows.Forms.ComboBox 
$DropdownYear.Location = New-Object System.Drawing.Size(445,238) 
$DropdownYear.Size = New-Object System.Drawing.Size(50,20) 
ForEach ($Year in $Years) {
 $DropdownYear.Items.Add($Year) | Out-Null
}
$DropdownYear.SelectedItem = $DropdownYear.Items[0]
$DropdownYear.Enabled = $False
$Form.Controls.Add($DropdownYear)

$treeView1 = New-Object System.Windows.Forms.TreeView
$treeView1.Size = New-Object System.Drawing.Size(245,350)
$treeView1.Name = "treeView1" 
$treeView1.Location = New-Object System.Drawing.Size(12,190)
$treeView1.DataBindings.DefaultDataSourceUpdateMode = 0 
$treeView1.TabIndex = 0 
$form.Controls.Add($treeView1)
    
$labelOU = New-Object System.Windows.Forms.Label
$labelOU.Name = "labelOU" 
$labelOU.Location = New-Object System.Drawing.Size(10,517)
$labelOU.Size = New-Object System.Drawing.Size(100,20)
$labelOU.Text = "AD User Location:"
$form.Controls.Add($labelOU) 
    
$textboxOU = New-Object System.Windows.Forms.TextBox
$textboxOU.Name = "textboxOU" 
$textboxOU.Location = New-Object System.Drawing.Size(12,545)
$textboxOU.Size = New-Object System.Drawing.Size(245,20)
$textboxOU.Text = ""
$textboxOU.Enabled = $false
$form.Controls.Add($textboxOU) 
$textboxOU.add_TextChanged({ Checkfortext })

$MsgBox = New-Object System.Windows.Forms.TextBox 
$MsgBox.Location = New-Object System.Drawing.Size(510,35) 
$MsgBox.Size = New-Object System.Drawing.Size(320,536) 
$msgBox.Font = $fontboldlog
$MsgBox.MultiLine = $True 
$MsgBox.ScrollBars = "Vertical"
$MsgBox.Enabled = $false 
$Form.Controls.Add($MsgBox)
     
############################################## end text fields

############################################## Start buttons

$Button = New-Object System.Windows.Forms.Button 
$Button.Location = New-Object System.Drawing.Size(328,580) 
$Button.Size = New-Object System.Drawing.Size(170,22) 
$Button.Text = "Create User" 
$Button.Enabled = $False
$Button.Add_Click({Start_Process}) 
$Form.Controls.Add($Button)

############################################## end buttons


$InitialFormWindowState = $form1.WindowState 
#Init the OnLoad event to correct the initial state of the form 
$form.add_Load($OnLoadForm_StateCorrection) 
#Show the Form 
[system.windows.forms.application]::run($form)
#$form.ShowDialog()| Out-Null