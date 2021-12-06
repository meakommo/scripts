#!/bin/bash

declare -a clients
clients[1]="ad.rgs.nz"
clients[2]="ruby.local"

declare -a clientallstaff
clientallstaff[1]="domainusers@ad.rgs.nz"
clientallstaff[2]="ad.allstaff@livinggems.com.au"

declare -a netusrnme
netusrnme[1]=kale.hembrow
netusrnme[2]=ad.admin



echo "Supported Client Codes \n
1 = TEST \n
2 = GEMS \n"
echo "Please enter the client code 1-9"
read clientCode
echo "Enter the Password for a domain administrator"
read passwd
localaccount= whoami
echo $localaccount

rc= ping -c 1 ${clients[$clientCode]}

if [[ $rc -eq 0 ]]; then
	dsconfigad -force -computer adm-mac -domain ${clients[$clientCode]} -username ${netusrnme[$clientCode]} -p $passwd -mobile enable -mobileconfirm disable -localhome enable -useuncpath enable -alldomains enable -groups ${clientallstaff[$clientCode]}
else
	echo "Unable to ping domain, check your connection to the domain and try again. \n EXITING!"
	break
fi
