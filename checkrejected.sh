#!/bin/bash

#usage: ./checkrejected.sh | tee rejected-analysis.txt

controlc() {
    exit 1
}

messagetolookfor="Rejecting connection with bad upgrade request"

journalctl | grep "$messagetolookfor" >badreqs.txt
cat badreqs.txt | cut -d ":" -f 9 | tr -d "]" >rejectedips.txt

sort rejectedips.txt | uniq | grep -v '^$' | while read ip; do
    trap controlc SIGINT
    echo -n "$ip":
    {
        whois "$ip" | grep country -i -m 1 | cut -d ':' -f 2 | xargs -0
        whois "$ip" | grep address -i -m 1 | cut -d ':' -f 2 | xargs -0
        grep -o "$ip" rejectedips.txt | wc -l
        cat badreqs.txt | grep "$ip" | cut -d "/" -f 2-
    } | tr "\n" " "
    echo -e "\r"
done
