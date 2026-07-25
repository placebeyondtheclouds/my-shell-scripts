#!/bin/bash

# SATA/SAS drives
for drive in /dev/sd[a-z]; do
    [ -b "$drive" ] || continue

    smart=$(sudo smartctl -a "$drive" 2>/dev/null)

    model=$(printf '%s\n' "$smart" |
        awk -F: '
        /Model Family|Device Model|Product/ {
            sub(/^[^:]*:[[:space:]]*/, "")
            print
            exit
        }')

    echo "$drive: $model"

    pss=$(printf '%s\n' "$smart" |
        awk '
        /Sector Sizes|Sector Size/ {
            if (match($0, /([0-9]+) bytes physical/, a)) {
                print a[1]
                exit
            }
        }')

    pss=${pss:-512}

    found=0

    printf '%s\n' "$smart" |
    awk -v devname="$drive" -v pss="$pss" '
        $1 == "241" || $1 == "246" {
            found=1
            B=$10 * pss
            printf("%s: Attribute %s: %.2f TiB (Physical Sector Size: %d bytes)\n",
                   devname, $1, B/1024^4, pss)
        }
        END {
            if (!found)
                exit 2
        }'

    if [ $? -eq 2 ]; then
        echo "$drive: no SATA write-total SMART attribute (241/246) found"
    fi

    echo
done


# NVMe drives
for drive in /dev/nvme[0-9]n[0-9]; do
    [ -b "$drive" ] || continue

    smart=$(sudo smartctl -a "$drive" 2>/dev/null)

    model=$(printf '%s\n' "$smart" |
        awk -F: '
        /Model Number/ {
            sub(/^[^:]*:[[:space:]]*/, "")
            print
            exit
        }')

    echo "$drive: $model"

    # NVMe Data Units Written are 1000 * 512-byte units
    printf '%s\n' "$smart" |
    awk -v devname="$drive" '
        /Data Units Written/ {
            gsub(",", "", $0)
            written=$4
            bytes=written * 1000 * 512
            printf("%s: Data Units Written: %.2f TiB\n",
                   devname, bytes/1024^4)
            found=1
        }
        END {
            if (!found)
                exit 2
        }'

    if [ $? -eq 2 ]; then
        echo "$drive: no NVMe Data Units Written counter found"
    fi

    echo
done