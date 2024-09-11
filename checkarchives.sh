#!/bin/bash

controlc() {
    exit 1
}

allfiles=$(find . -type f \( -name "*.7z" -o -name "*.tar.gz" -o -name "*.gz" \) 2>/dev/null | sort -n)
echo "Total files: $(echo "$allfiles" | wc -l)"
echo >fileswitherrors.txt

for file in $allfiles; do
    trap controlc SIGINT
    if [[ "$file" == *.7z ]]; then
        7z t "$file" >/dev/null 2>&1
    elif [[ "$file" == *.tar.gz ]]; then
        tar -tzf "$file" >/dev/null 2>&1
    elif [[ "$file" == *.gz ]]; then
        gunzip -t "$file" >/dev/null 2>&1
    fi

    if [ $? -ne 0 ]; then
        echo -e "\n File $file is corrupted" | tee -a fileswitherrors.txt
    else
        echo -n "."
    fi
done
#for file in $(cat fileswitherrors.txt | cut -d " " -f 3); do rm -f $file; done
