#!/bin/bash

#sudo apt install p7zip-full p7zip-rar libarchive-tools

# GNU tar takes longer because it is scanning the entire original archive before appending.
# The bsdtar command from libarchive just immediately appends the new data.
# https://superuser.com/questions/1456587/why-does-each-subsequent-append-to-a-tar-archive-take-longer

controlc() {
    exit 1
}

declare -a archivefiles
IFS=$'\n'

for line in $(find . -type f \( -name "*.7z" -o -name "*.rar" -o -name "*.zip" \) 2>/dev/null | sort -n); do
    archivefiles+=("$line")
done

for ((archno = 0; archno < ${#archivefiles[@]}; archno++)); do
    trap controlc SIGINT

    archivefile="${archivefiles[$archno]}"
    echo -e "\nProcessing $archivefile"
    echo -n "testing $archivefile..."
    7z t "$archivefile" &>/dev/null
    if [ ! $? -eq 0 ]; then
        echo "original ${archivefiles[$archno]} is damaged, status: $?"
        exit 1
    fi
    echo "OK"
    tarfile="${archivefile%.*}.tar"
    if [ -f "$tarfile" ]; then
        rm -f "$tarfile"
    fi

    # extract to a temp directory
    mkdir -p ./temp
    tempdir="./temp"
    echo "extracting $archivefile to $tempdir"
    7z x "$archivefile" -o"$tempdir"
    if [ ! $? -eq 0 ]; then
        echo "failed to extract $archivefile, status: $?"
        exit 1
    fi

    # create a tar archive
    echo "creating $tarfile"
    tar cf "$tarfile" -C "$tempdir" .
    if [ ! $? -eq 0 ]; then
        echo "failed to create $tarfile, status: $?"
        exit 1
    fi

    echo -ne "\ntesting $tarfile..."
    if ! tar -tf "$tarfile" &>/dev/null; then
        echo "created $tarfile is damaged, status: $?"
        exit 1
    fi
    echo "OK"
done

# delete the temp directory on exit
trap "rm -rf $tempdir" EXIT
