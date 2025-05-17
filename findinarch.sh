#!/bin/bash

controlc() {
    exit 1
}

trap controlc SIGINT

allfiles=$(find . -type f \( -name "*.7z" -o -name "*.tar.gz" -o -name "*.gz" \) 2>/dev/null | sort -n)
echo "Total files: $(echo "$allfiles" | wc -l)"
echo >report.txt

for file in $allfiles; do
    echo "Searching $file..." | tee -a report.txt
    if [[ "$file" == *.7z ]]; then
        7z e -so ${file} | grep --color=always -n "$1" | tee -a report.txt
    elif [[ "$file" == *.tar.gz ]]; then
        tar -xzOf ${file} | grep --color=always -n "$1" | tee -a report.txt
    elif [[ "$file" == *.gz ]]; then
        zgrep --color=always -n "$1" ${file} | tee -a report.txt
    #zcat ${file} | grep --color=always -n "$1" | tee -a report.txt
    fi
done
