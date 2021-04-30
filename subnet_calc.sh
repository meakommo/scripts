#!/bin/bash

# Calculates network and broadcast based on supplied ip address and netmask

# Usage: broadcast_calc.sh 192.168.0.1 255.255.255.0
# Usage: broadcast_calc.sh 192.168.0.1/24


tonum() {
    if [[ $1 =~ ([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+) ]]; then
        addr=$(( (${BASH_REMATCH[1]} << 24) + (${BASH_REMATCH[2]} << 16) + (${BASH_REMATCH[3]} << 8) + ${BASH_REMATCH[4]} ))
        eval "$2=\$addr"
    fi
}
toaddr() {
    b1=$(( ($1 & 0xFF000000) >> 24))
    b2=$(( ($1 & 0xFF0000) >> 16))
    b3=$(( ($1 & 0xFF00) >> 8))
    b4=$(( $1 & 0xFF ))
    eval "$2=\$b1.\$b2.\$b3.\$b4"
}

if [[ $1 =~ ^([0-9\.]+)/([0-9]+)$ ]]; then
    # CIDR notation
    IPADDR=${BASH_REMATCH[1]}
    NETMASKLEN=${BASH_REMATCH[2]}
    zeros=$((32-NETMASKLEN))
    NETMASKNUM=0
    for (( i=0; i<$zeros; i++ )); do
        NETMASKNUM=$(( (NETMASKNUM << 1) ^ 1 ))
    done
    NETMASKNUM=$((NETMASKNUM ^ 0xFFFFFFFF))
    toaddr $NETMASKNUM NETMASK
else
    IPADDR=${1:-192.168.1.1}
    NETMASK=${2:-255.255.255.0}
fi

tonum $IPADDR IPADDRNUM
tonum $NETMASK NETMASKNUM

#printf "IPADDRNUM: %x\n" $IPADDRNUM
#printf "NETMASKNUM: %x\n" $NETMASKNUM

# The logic to calculate network and broadcast
INVNETMASKNUM=$(( 0xFFFFFFFF ^ NETMASKNUM ))
NETWORKNUM=$(( IPADDRNUM & NETMASKNUM ))
BROADCASTNUM=$(( INVNETMASKNUM | NETWORKNUM ))


toaddr $NETWORKNUM NETWORK
toaddr $BROADCASTNUM BROADCAST

printf "%-25s %s\n" "IPADDR=$IPADDR"       
printf "%-25s %s\n" "NETMASK=$NETMASK"     
printf "%-25s %s\n" "NETWORK=$NETWORK"     
printf "%-25s %s\n" "BROADCAST=$BROADCAST" 
