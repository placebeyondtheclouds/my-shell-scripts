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

## working with tar archives

- Archive directories of a current directory into tar.gz files. If run with a parameter of a path, the script will save the archives to the path. Otherwise, the archives will be saved to the current directory. Uncomment needed parts of the code. `./archivedirs.sh /path/to/save` without the trailing slash. [archivedirs.sh](archivedirs.sh)

- strip the gzip compression from from tar.gz on the fly

  - `zcat cv-corpus-15.0-2023-09-08-ca.tar.gz > cv-corpus-15.0-2023-09-08-ca.tar`

- likewise, creating tar archives from multiple tar.gz, tgz, and other archive files in the current directory on the fly

  - `for onetgz in *.tar.gz; do echo "转换ing $onetgz"; zcat $onetgz > ${onetgz%.gz}; done`

  - `for onetgz in *.tgz; do echo "转换ing $onetgz"; zcat $onetgz > ${onetgz%.tgz}.tar; done`

  - for other archive formats [repacktotar.sh](repacktotar.sh): `./repacktotar.sh`

- creating tar archives on the fly from multipart `*.tar.gz.aa *.tar.gz.ab` etc.: [multipart-targz-to-tar.sh](multipart-targz-to-tar.sh). run it like `./multipart-targz-to-tar.sh /path/to/destination`

- test tar - `tar -tf file.tar &> /dev/null && echo "tar is good"`

## mounting tar archives as directories

- install [ratarmount](https://github.com/mxmlnkn/ratarmount) `conda install -c conda-forge ratarmount` or `pip install ratarmount`
- use mount-tars.sh: `./mount-tars.sh /path/to/tars path/to/mountpoint`

## file checksums

### method 1:

relative paths, current directory with it's subdirectories, overwrites existing checksum file

- on a MacOS:

  - create:

    ```
    find . -type f -exec md5 -r {} \; > checksums.md5
    ```

  - verify:

    ```
    while read -r checksum file; do
        calculated_checksum=$(md5 -r "$file" | awk '{print $1}')
        if [[ $checksum != $calculated_checksum ]]; then
            echo "Checksum verification failed for $file"
        fi
    done < checksums.md5
    ```

- on Linux:

  - create:

    ```
    find . -type f -exec md5sum {} \; > checksums.md5
    ```

  - verify:

    ```
    while read -r checksum file; do
        calculated_checksum=$(md5sum "$file" | awk '{print $1}')
        if [[ $checksum != $calculated_checksum ]]; then
            echo "Checksum verification failed for $file"
        fi
    done < checksums.md5
    ```

### method 2:

relative paths, current directory only

- on Linux:

  - create:

    ```
    md5sum * > checklist.chk
    ```

  - verify:

    ```
    md5sum -c checklist.chk
    ```

### method 3:

relative paths, current directory with it's subdirectories, one checksum file per directory, doesn't overwrite existing checksum files, displays progress. https://askubuntu.com/questions/318530/generate-md5-checksum-for-all-files-in-a-directory

- on Linux:

  - create:

    ```
    find "$PWD" -type d | sort | while read dir; do cd "${dir}"; [ ! -f @md5Sum.md5 ] && echo "Processing " "${dir}" || echo "Skipped " "${dir}" " @md5Sum.md5 already present" ; [ ! -f @md5Sum.md5 ] &&  md5sum * > @md5Sum.md5 ; chmod a=r "${dir}"/@md5Sum.md5 ;done
    ```

  - verify:

    ```
    find "$PWD" -name @md5Sum.md5 | sort | while read file; do cd "${file%/*}"; md5sum -c @md5Sum.md5; done > checklog.txt
    ```

### analyze the checksum check log

```
import pandas as pd

log_file_name = "checklog.txt"
df = pd.read_csv(log_file_name, sep=":", header=None, names=["file", "result"])
df_bad = df[~df["result"].str.contains("OK")]
print("total:", len(df))
print("bad:", len(df_bad))
df_bad.tail(10)
```
