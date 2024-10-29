#!/bin/bash
# smart parameters references https://www.backblaze.com/blog/making-sense-of-ssd-smart-stats/

for drive in /dev/sd[a-z]; do
    model=$(sudo smartctl -a $drive | awk -F: '/Model Family/ {print $2}' | xargs)

    case "$model" in
    *Intel*)
        onewrite=32768
        sudo smartctl --attributes $drive | awk -v devname=$drive -v onewrite=$onewrite '
            /(241)/ {
              B=$10 * onewrite;
              printf("%s: Attribute %d, Intel: %.2f TiB \n", devname, $1, B/1024^4, onewrite)
            }'
        ;;
    #any other vendor
    *)

        pss=$(
            sudo smartctl -a $drive | awk '
                /Sector Sizes|Sector Size/ {
                    if ($0 ~ /logical\/physical/) {
                        split($0, a, /[ ,/]/);
                        for (i in a) if (a[i] == "physical") {print a[i-3]; break}
                    } else if ($0 ~ /physical/) {
                        split($0, a, /[ ,/]/);
                        for (i in a) if (a[i] == "physical") {print a[i-2]; break}
                    }
                }'
        )

        sudo smartctl --attributes $drive | awk -v devname=$drive -v pss=$pss '
            /(241|246)/ {
              B=$10 * pss;
              printf("%s: Attribute %d: %.2f TiB (Physical Sector Size: %d bytes)\n", devname, $1, B/1024^4, pss)
            }'
        ;;

    esac
done
