#!/bin/bash
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

declare -A clients
clients[TEST]="ad.rgs.nz"
clients[GEMS]="ruby.local"

echo "Supported Client Codes \n
GEMS"
echo "Please enter the client code"
read clientCode

echo "Please enter Domain admin account details"
echo "Username"
read username
echo "Please enter the destination OU"
read orgunit


sudo dsconfigad -a $HOSTNAME -u $username -ou $orgunit -domain client[$clientCode] -mobile enable -mobileconfirm enable -localhome enable -useuncpath enable -alldomains enable -status

sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -off -restart -agent -privs -all -allowAccessFor -allUsers
sleep 60
echo "The computer will reboot in 60 seconds"
shutdown -r now
