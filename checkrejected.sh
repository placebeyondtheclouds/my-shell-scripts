#!/bin/bash

#usage: ./checkrejected.sh | tee rejected-analysis.txt

controlc() {
    exit 1
}

trap controlc SIGINT

messagetolookfor="Rejecting connection with bad upgrade request"

journalctl | grep "$messagetolookfor" >badreqs.txt
cat badreqs.txt | cut -d ":" -f 9 | tr -d "]" >rejectedips.txt

sort rejectedips.txt | uniq -c | grep -v '^$' | sort -nr | while read count ip; do
    echo -n "$ip":
    {
        echo -n "Count: "
        grep -o "$ip" rejectedips.txt | wc -l
        echo -n "Country: "
        whois "$ip" | grep country -i -m 1 | cut -d ':' -f 2 | xargs -0
        echo -n "Address: "
        whois "$ip" | grep address -i -m 1 | cut -d ':' -f 2 | xargs -0
        echo -n "Request content: "
        cat badreqs.txt | grep "$ip" | cut -d "/" -f 2-
    } | tr "\n" " "
    echo -e "\r"
done
