#!/bin/bash

controlc() {
    exit 1
}

messagetolookfor="error while accepting TLS connection"

journalctl | grep "$messagetolookfor" >errors.txt
cat errors.txt | cut -d ":" -f 9 | tr -d "]" >errorips.txt

sort errorips.txt | uniq | grep -v '^$' | while read ip; do
    trap controlc SIGINT
    echo -n "$ip":
    {
        whois "$ip" | grep country -i -m 1 | cut -d ':' -f 2 | xargs
        whois "$ip" | grep address -i -m 1 | cut -d ':' -f 2 | xargs
        grep -o "$ip" errorips.txt | wc -l
        cat errors.txt | grep "$ip" | cut -d ":" -f 16-
    } | tr "\n" " "
    echo -e "\r"
done
