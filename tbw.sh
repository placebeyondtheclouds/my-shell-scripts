#!/bin/bash
# smart parameters references https://www.backblaze.com/blog/making-sense-of-ssd-smart-stats/

for drive in /dev/sd[a-z]; do
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

    # Debugging information
    #echo "Drive: $drive, Physical Sector Size: $pss"

    # Check if pss is empty or zero
    if [[ -z "$pss" || "$pss" == "bytes" || "$pss" -eq 0 ]]; then
        echo "Error: Failed to get physical sector size for $drive"
        continue
    fi

    sudo smartctl --attributes $drive | awk -v devname=$drive -v pss=$pss '
    /(241|246)/ {
      B=$10 * pss;
      printf("%s: Attribute %d: %.2f TiB (Physical Sector Size: %d bytes)\n", devname, $1, B/1024^4, pss)
    }'
done
