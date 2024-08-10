# my shell scripts

The shell scripts that I use for daily tasks.

## Log parser 1

This script is parsing journalctl logs, looking for a message from the websocket tunnel service(s) that indicates a port scan. Then the script extracts unique IPs and whois them to their country and address, adding number of requests and the request that was used in the connection attempt. The script is run with `./checkrejected.sh | tee rejected-analysis.txt`.

```
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
```

The journalctl is set to preserve the logs

`nano /etc/systemd/journald.conf`

```
[Journal]
Storage=persistent
SystemMaxUse=5000M
```

`sudo mkdir /var/log/journal`

`sudo systemctl restart systemd-journald`
