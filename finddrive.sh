#!/bin/bash

controllers=()
IFS=$'\n'
for onecontroller in $(lspci | grep -e "SAS" -e "SATA"); do
    controllers+=("$onecontroller")
done

for onecontroller in "${controllers[@]}"; do
    echo $onecontroller
    controlleraddr=$(echo $onecontroller | awk '{print $1}')
    for onedisk in $(ls -l /sys/block | grep $controlleraddr | awk '{print $11}'); do
        echo $onedisk
        onediskname=$(echo $onedisk | awk -F/ '{print $NF}')
        oneport=$(ls /sys/block/$onediskname/device/scsi_device/)
        echo $(dmesg | grep "${oneport:0:-1}" | grep "slot(" | head -n 1)
        echo ""
    done
done
