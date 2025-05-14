#!/bin/bash

update_mac() {
    echo "Current MAC address:"
    # it's funny that both strings have the word I need at the same place
    ip link show | grep -i $wifiif -A 1 | awk '{print $2}'
    # also turn off this
    sudo /sbin/iw $wifiif set power_save off
    sudo iwconfig $wifiif power off
    echo "hostname:" $(hostname)
    macaddr=$(echo $(hostname) $wifiif | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
    sudo ip link set dev $wifiif down
    sudo ip link set dev $wifiif address $macaddr
    sudo ip link set dev $wifiif up
    echo "New MAC address:"
    ip link show | grep -i $wifiif -A 1 | awk '{print $2}'
    echo "---"
}

if [ $1 ]; then
    wifiif=$1
else
    wifiifall=$(ip link show | grep -i "wl" | awk '{print $2}' | sed 's/://')
    wifiifnum=$(echo "$wifiifall" | nl)
    echo "$wifiifnum"
    read -p "Enter the number of the wifi interface: " wifiifnum
    if [ -z "$wifiifnum" ]; then
        # do every interface
        for wifiif in $wifiifall; do
            update_mac
        done
    else
        wifiif=$(echo "$wifiifall" | sed -n "${wifiifnum}p")
        update_mac
    fi
fi
