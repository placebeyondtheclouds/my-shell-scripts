#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <file_with_links>"
    exit 1
fi

controlc() {
    exit 1
}

cat $1 | while read link; do
    trap controlc SIGINT
    if [ -n "$link" ]; then
        fname=$(echo "$link" | cut -d "/" -f 6)
        if [ -f $fname ]; then
            size_disk=$(stat -c%s "$fname")
            size_url=$(curl -sI "$link" | grep -i Content-Length | cut -d " " -f 2 | tr -d '\r\n')
            if [ "$size_disk" -eq "$size_url" ]; then
                echo "File $fname already exists and is of the correct size."
                continue
            fi
        fi
        echo "Downloading $fname"
        curl -# "$link" -o $fname
    fi
done
