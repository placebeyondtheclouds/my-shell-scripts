#!/bin/bash

controlc() {
    exit 1
}

trap controlc SIGINT

messagetolookfor="Rejecting connection with bad upgrade request"

journalctl | grep "$messagetolookfor" >badreqs.txt
cat badreqs.txt | cut -d ":" -f 9 | tr -d "]" >rejectedips.txt

sort rejectedips.txt | uniq | grep -v '^$' | while read ip; do
    echo -n "$ip":
    {
        whois "$ip" | grep country -i -m 1 | cut -d ':' -f 2 | xargs
        whois "$ip" | grep address -i -m 1 | cut -d ':' -f 2 | xargs
        grep -o "$ip" rejectedips.txt | wc -l
        cat badreqs.txt | grep "$ip" | cut -d "/" -f 2-
    } | tr "\n" " "
    echo -e "\r"
done
