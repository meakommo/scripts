#!/bin/bash

declare -A clients
clients[GEMS]="ruby.local"

echo "Supported Client Codes \n
GEMS"
echo "Please enter the client code"
read clientCode

echo "Please enter Domain admin account details"
echo "Username"
read username
echo "Password"
read passWord
echo "Please enter the destination OU"
read orgunit


dsconfigad -a $HOSTNAME -u $username -ou $orgunit -domain client[$clientCode] -mobile enable -mobileconfirm enable -localhome enable -useuncpath enable -alldomains enable
