#!/bin/bash

#sudo apt install p7zip-full

controlc() {
    exit 1
}

RAMDISK="/mnt/ramdisk"

prefix=""
if [ "$EUID" != 0 ]; then
    prefix="sudo"
fi

$prefix mkdir -p $RAMDISK
$prefix mount -t tmpfs -o size=512M tmpfs $RAMDISK
$prefix chown $USER:$USER $RAMDISK -R

for archive in $(find . -type f \( -name "*.7z" -o -name "*.rar" -o -name "*.zip" \) 2>/dev/null | sort -n); do
    trap controlc SIGINT
    echo "Processing $archive"
    echo "testing"
    7z t "$archive"
    if [ ! $? -eq 0 ]; then
        echo "original $archive is damaged, status: $?"
        exit 1
    fi
    tarfile="${archive%.*}.tar"
    if [ -f "$tarfile" ]; then
        rm -f "$tarfile"
    fi
    filelist=$(7z l -ba "$archive" | grep -vF 'D....' | grep -oP '(?<=^.{53}).*')
    if [ -z "$filelist" ]; then
        continue
    fi
    for filenameinarchive in $filelist; do
        echo -n "."
        mkdir -p "$RAMDISK/$(dirname "$filenameinarchive")"
        7z x -so "$archive" "$filenameinarchive" >"$RAMDISK/$filenameinarchive"
        if [ ! -f "$tarfile" ]; then
            tar --create --file="$tarfile" --transform="s|^|$filenameinarchive|" -C "$RAMDISK" "$filenameinarchive"
        else
            tar --append --file="$tarfile" --transform="s|^|$filenameinarchive|" -C "$RAMDISK" "$filenameinarchive"
        fi
        $prefix rm -rf "$RAMDISK/$filenameinarchive"

    done
done

$prefix umount $RAMDISK
$prefix rmdir $RAMDISK
