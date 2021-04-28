#!/bin/bash

#sudo AssetCacheManagerUtil deactivate
echo "Lets begin setting up the Apple cache server"
echo "First of all we will need some IPs, if you don't already have them then go ahead and prepare them now"
echo "Each BCE school should have 5 IP Listening ranges"
echo "VLAN: 2,590,595,600 and 605"
echo "These can be found by going to Sharepoint>Technical Standards and Procedures>BCEC>IP Addressing>LinCSPlus_IP_Addressing.xls"
echo "If you need a subnet calculator you can be found here https://www.subnet-calculator.com/subnet.php?net_class=B"
echo "Let's begin"
Sleep 1

# Records the IP ranges from user input
echo "Enter the starting IP of the First VLAN"
read firstVLANStart
echo "Enter the Ending IP of the First VLAN"
read firstVLANEnd

echo "Enter the starting IP of the Second VLAN"
read secondVLANStart
echo "Enter the Ending IP of the Second VLAN"
read secondVLANEnd

echo "Enter the starting IP of the Third VLAN"
read thirdVLANStart
echo "Enter the Ending IP of the Third VLAN"
read thirdVLANEnd

echo "Enter the starting IP of the Fourth VLAN"
read fourthVLANStart
echo "Enter the Ending IP of the Fourth VLAN"
read fourthVLANEnd

echo "Enter the starting IP of the Fifth VLAN"
read fifthVLANStart
echo "Enter the Ending IP of the Fifth VLAN"
read fifthVLANEnd

Sleep 1

clear 

echo "Now that we have the IP ranges lets setup the Network adaptor on the caching server"

Sleep 1


echo "Enter the Static IP address that you will use for the server"
read serveraddress
echo "Enter the Subnet mask of the server default 255.255.255.0"
read subnetmask
echo "enter the gateway/router address"
read gateway




sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist AllowPersonalCaching true
sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist AllowSharedCaching true
sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist AllowTetheredCaching false
sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist CacheLimit 180000000000




sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist ListenRanges '( 
    { first = '$firstVLANStart'; last = '$firstVLANEnd'; },
    { first = '$secondVLANStart'; last = '$secondVLANEnd'; },
    { first = '$thirdVLANStart'; last = '$thirdVLANEnd'; },
    { first = '$fourthVLANStart'; last = '$fourthVLANEnd'; },
    { first = '$fifthVLANStart'; last = '$fifthVLANEnd'; }
 
  )'

sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist ListenRangesOnly true

sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist LocalSubnetsOnly false

sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist ParentSelectionPolicy round-robin

sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist PeerFilterRanges '( 
    { first = '$firstVLANStart'; last = '$firstVLANEnd'; },
    { first = '$secondVLANStart'; last = '$secondVLANEnd'; },
    { first = '$thirdVLANStart'; last = '$thirdVLANEnd'; },
    { first = '$fourthVLANStart'; last = '$fourthVLANEnd'; },
    { first = '$fifthVLANStart'; last = '$fifthVLANEnd'; }
 
  )'

sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist PeerListenRanges '( 
    { first = '$firstVLANStart'; last = '$firstVLANEnd'; },
    { first = '$secondVLANStart'; last = '$secondVLANEnd'; },
    { first = '$thirdVLANStart'; last = '$thirdVLANEnd'; },
    { first = '$fourthVLANStart'; last = '$fourthVLANEnd'; },
    { first = '$fifthVLANStart'; last = '$fifthVLANEnd'; }
 
  )'

sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist PeerLocalSubnetsOnly false

echo "Enter the starting IP of the First PublicRanges"
read firstVLANStart
echo "Enter the Ending IP of the First PublicRanges"
read firstVLANEnd

echo "Enter the starting IP of the Second PublicRanges"
read secondVLANStart
echo "Enter the Ending IP of the Second PublicRanges"
read secondVLANEnd

sudo -u _assetcache defaults write /Library/Preferences/com.apple.AssetCache.plist PublicRanges '( 
    { first = '$firstVLANStart'; last = '$firstVLANEnd'; },
    { first = '$secondVLANStart'; last = '$secondVLANEnd'; }
  )'


# sudo AssetCacheManagerUtil activate

exit
