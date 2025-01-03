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

## Parsing logs

```shell
find . -type f -iname "*.log" -exec grep --color=always -Hi -B 1 -A 1 "core dumped" '{}' + ;

find . -type f -name "*.log" | xargs cat | grep -e "core dumped" -C1

find . -type f -name "*.log" | xargs cat | grep -E -i -w "word1|word2|word3" -C1
```

## Find in code

```shell
find . -type f -iname "*.py" -exec grep -Hi "import pandas as pd" '{}' + | grep -v "#"
find . -type f -iname "*.py" -exec grep --color=always -Hi "import jieba" '{}' + 2>/dev/null | grep -v ".check"
```

## Check archives in current directory for errors

Usage: `./checkarchives.sh`
Link to the file: [checkarchives.sh](checkarchives.sh)

## Find a string within a file within archives in current directory

The archive is extracted to the standard output and then grepped for the string. Needs optimization. Run with `./findinarch.sh "string"`.
Link to the file: [findinarch.sh](findinarch.sh)

## Find and highlight a string within all files

Inspired by a line from Heath Adams course on privesc:

```shell
grep --color=always -rn '.' --include \*.sh -ie "/dev/tcp/" 2>/dev/null

grep --color=always -rn '/' -ie "password" 2>/dev/null
```

## start multiple ollama serve

[ollamaparallel.sh](ollamaparallel.sh)

## working with tar archives

- Archive directories of a current directory into tar.gz files. If run with a parameter of a path, the script will save the archives to the path. Otherwise, the archives will be saved to the current directory. Uncomment needed parts of the code. `./archivedirs.sh /path/to/save` without the trailing slash. [archivedirs.sh](archivedirs.sh)

- strip the gzip compression from from tar.gz on the fly

```shell
zcat cv-corpus-15.0-2023-09-08-ca.tar.gz > cv-corpus-15.0-2023-09-08-ca.tar
```

- likewise, creating tar archives from multiple tar.gz, tgz, and other archive files in the current directory on the fly

  ```shell
  for onetgz in *.tar.gz; do echo "转换ing $onetgz"; zcat $onetgz > ${onetgz%.gz}; done
  ```

  ```shell
  for onetgz in *.tgz; do echo "转换ing $onetgz"; zcat $onetgz > ${onetgz%.tgz}.tar; done
  ```

  for other archive formats [repacktotar.sh](repacktotar.sh): `./repacktotar.sh`

- creating tar archives on the fly from multipart `*.tar.gz.aa *.tar.gz.ab` etc.: [multipart-targz-to-tar.sh](multipart-targz-to-tar.sh). run it like `./multipart-targz-to-tar.sh /path/to/destination`

- test tar - `tar -tf file.tar &> /dev/null && echo "tar is good"`

## mounting tar archives as directories

- install [ratarmount](https://github.com/mxmlnkn/ratarmount) `conda install -c conda-forge ratarmount` or `pip install ratarmount`
- use [mount-tars.sh](mount-tars.sh): `./mount-tars.sh /path/to/tars path/to/mountpoint`

## file checksums

### method 1:

relative paths, current directory with it's subdirectories, overwrites existing checksum file

- on a MacOS:

  - create:

    ```shell
    find . -type f -exec md5 -r {} \; > checksums.md5
    ```

  - verify:

    ```shell
    while read -r checksum file; do
        calculated_checksum=$(md5 -r "$file" | awk '{print $1}')
        if [[ $checksum != $calculated_checksum ]]; then
            echo "Checksum verification failed for $file"
        fi
    done < checksums.md5
    ```

- on Linux:

  - create:

    ```shell
    find . -type f -exec md5sum {} \; > checksums.md5
    ```

  - verify:

    ```shell
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

    ```shell
    md5sum * > checklist.chk
    ```

  - verify:

    ```shell
    md5sum -c checklist.chk
    ```

### method 3:

relative paths, current directory with it's subdirectories, one checksum file per directory, doesn't overwrite existing checksum files, displays progress. https://askubuntu.com/questions/318530/generate-md5-checksum-for-all-files-in-a-directory

- on Linux:

  - create:

    ```shell
    find "$PWD" -type d | sort | while read dir; do cd "${dir}"; [ ! -f @md5Sum.md5 ] && echo "Processing " "${dir}" || echo "Skipped " "${dir}" " @md5Sum.md5 already present" ; [ ! -f @md5Sum.md5 ] &&  md5sum * > @md5Sum.md5 ; chmod a=r "${dir}"/@md5Sum.md5 ;done
    ```

  - verify:

    ```shell
    find "$PWD" -name @md5Sum.md5 | sort | while read file; do cd "${file%/*}"; md5sum -c @md5Sum.md5; done > checklog.txt
    ```

### analyze the checksum check log

```python
#!/usr/bin/env python
import pandas as pd

log_file_name = "checklog.txt"
df = pd.read_csv(log_file_name, sep=":", header=None, names=["file", "result"])
df_bad = df[~df["result"].str.contains("OK")]
print("total:", len(df))
print("bad:", len(df_bad))
print(df_bad)
```

## extract all zip archives in the current directory to their own directories

```shell
for file in *.zip; do unzip -d "${file%.*}" "$file"; done
```

## extract all tar.gz archives in the current directory

```shell
for file in *.tar.gz; do echo "Extracting $file"; tar -xzf "$file"; done
```

## extract all \*.gz archives in the current directory to a specified location

```shell
controlc() { echo "SIGINT caught"; exit; }; trap controlc SIGINT; for file in *.gz; do
echo "Extracting $file"; gunzip -c "$file" > /path/to/destination/"${file%.gz}";
done
```

## test all gzip archives in the current directory and rm failed ones

```shell
controlc() { echo "SIGINT caught"; exit; }; trap controlc SIGINT; for file in *.gz; do
echo "Testing $file"; zcat "$file" > /dev/null; if [ $? -eq 0 ]; then echo "OK"; else echo "Failed"; rm "$file"; fi;
done
```

## exfil

```shell
#pack on a remote machine without compression and send over ssh
ssh user@ip "zip -r -0 - /path/to/dir" > local_archive.zip
ssh user@ip "tar -cf - /path/to/dir" > local_archive.tar

#compressed
ssh user@ip "tar czf - /path/to/dir" | cat > local_archive.tar.gz

#pack a directory into a tar and send it over ssh to a remote machine
tar -cf - /path/to/dir | ssh user@ip "cat > local_archive.tar"
```

## Get TBW (Total Bytes Written) for all drives that support the attribute

TBW is calculated as `total LBA writes * physical block size`. Different drives have different physical block sizes, the exact value should be taken from the SMART report. Total LBA writes is stored in different attributes for different manufacturers. Intel also counts it differently, the raw value is increased by 1 for every 65,536 sectors (32MB) written by the host.

The script for TBW [tbw.sh](tbw.sh)

## drives

find the physical slot of a drive in a server [finddrive.sh](finddrive.sh)

## Find a message in dmesg logs and convert the timestamps to human-readable format

```shell
sudo dmesg | grep "I/O error, dev " | while read -r line; do
timestamp=$(echo "$line" | grep -oP '\[\s*\K[0-9]+\.[0-9]+(?=\])')
boot_time=$(date -d "$(uptime -s)" +%s)
timestamp_int=${timestamp%.*}
log_time=$((boot_time + timestamp_int))
formatted_date=$(date -d "@$log_time" +"[%Y-%m-%d %H:%M:%S]")
echo "$line" | sed "s/\[\s*$timestamp\]/$formatted_date/"
done
```

## image processing

- `sudo apt install imagemagick libimage-exiftool-perl`

- remove exif data from all images in the current directory

  ```shell
  exiftool -all= *.jpg
  ```

- rename the files with date and time from exif data

  ```shell
  IFS=$'\n'
  for file in $(ls | grep -a -i -e ".jpg"); do
  date=$(exiftool -s -s -s -d "%Y-%m-%d %H.%M.%S" -DateTimeOriginal "$file")
  if [ ! -z "$date" ]; then
  mv "$file" "$date.jpg"
  echo "$file -> $date.jpg"
  else
  echo "No exif data for $file"
  fi
  done
  ```

- convert png to jpg

  ```shell
  for file in $(ls | grep -a -i -e ".png"); do
  convert "$file" "${file%.png}.jpg"
  echo "$file -> ${file%.png}.jpg"
  done
  ```

- resize jpg to 50%

  ```shell
  mkdir -p resized
  IFS=$'\n'
  for file in $(ls | grep -a -i -e ".jpg"); do
  convert "$file" -resize 50% resized/"$file"
  echo "$file -> resized/$file"
  done
  ```

- another way is to use ffmpeg:

  ```shell
  ffmpeg -i image.jpeg -map_metadata -1 -c:v copy stripped.jpeg
  exiftool -if '$gps*' -gps* "stripped.jpeg"
  ```

## batch rename files

```shell
IFS=$'\n'; mkv_files=($(ls *.mkv)); for i in "${!mkv_files[@]}"; do mv "${mkv_files[i]}" "S01E$(printf "%02d" $((i + 1))).mkv"; done
```

## split the file into parts of 500MB (for instance, for uploading large files to github LFS)

```shell
#split
sha256sum file.tar > checksum.sha256
split -b 500M file.tar file.tar.part-
#combine
cat file.tar.part-?? > file.tar
sha256sum -c checksum.sha256 | grep "OK"
```
