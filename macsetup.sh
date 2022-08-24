#This script has been written in a way were it could be used to connect to multiple Active directory by adding them to the object

#Domain list
declare -a clients
clients[1]="reiq.com.au"

#default user group for the domain that all users are a member of
declare -a clientallstaff
#I believe that this is correct for REIQ 
clientallstaff[1]="users@reiq.com.au"


echo "Supported Client Codes \n
1 = REIQ \n"
echo "Please enter the client code"
read clientCode
echo "Enter username with device enrollment right"
read netusrnme
echo "Password"
read passwd
localaccount= whoami
computername= hostname
echo $localaccount

rc= ping -c 1 ${clients[$clientCode]}
joindom=$( dsconfigad -show | awk '/Active Directory Domain/{print $NF}' )

if [[ $joindom == ${clients[$clientCode]} ]]; then
	echo "\n\nThe computer is already joined to" ${clients[$clientCode]} "\n\nEXITING\n\n"
	break
else
	if [[ $rc -eq 0 ]]; then
		dsconfigad -force -computer $computername -domain ${clients[$clientCode]} -username $netusrnme -p $passwd -mobile enable -mobileconfirm disable -localhome enable -useuncpath enable -alldomains enable -groups ${clientallstaff[$clientCode]}
	else
		echo "Unable to ping domain, check your connection to the domain and try again. \n EXITING!"
		break
	fi
fi
