# my shell scripts

The shell scripts that I use for daily tasks.

## Log parser for journalctl

This script is parsing journalctl logs, looking for an error message from the wstunnel service(s) that indicates a port scan. Then the script extracts unique IPs and whois them to their country and address, adding number of requests and the request that was used in the connection attempt. The script is run with `./checkrejected.sh | tee rejected-analysis.txt`.
Link to the file: [checkrejected.sh](checkrejected.sh)

The journalctl is set to preserve the logs

`nano /etc/systemd/journald.conf`

```
[Journal]
Storage=persistent
SystemMaxUse=5000M
```

`sudo mkdir /var/log/journal`

`sudo systemctl restart systemd-journald`

## Check archives in current directory for errors

Usage: `./checkarchives.sh`
Link to the file: [checkarchives.sh](checkarchives.sh)

## Find a string within a file within archives in current directory

The archive is extracted to the standard output and then grepped for the string. Needs optimization. Run with `./findinarch.sh "string"`.
Link to the file: [findinarch.sh](findinarch.sh)

## Find and highlight a string within all files

Inspired by a line from Heath Adams course on privesc

`grep --color=always -rn '.' --include \*.sh -ie "/dev/tcp/" 2>/dev/null`

`grep --color=always -rn '/' -ie "password" 2>/dev/null`

## start multiple ollama serve

[ollamaparallel.sh](ollamaparallel.sh)
