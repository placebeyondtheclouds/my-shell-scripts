#!/bin/bash

#sudo apt install p7zip-full p7zip-rar libarchive-tools

# GNU tar takes longer because it is scanning the entire original archive before appending.
# The bsdtar command from libarchive just immediately appends the new data.
# https://superuser.com/questions/1456587/why-does-each-subsequent-append-to-a-tar-archive-take-longer

controlc() {
    exit 1
}

RAMDISK="/mnt/ramdisk"

prefix=""
if [ "$EUID" != 0 ]; then
    prefix="sudo"
fi

declare -a filelist
declare -a archivefiles
IFS=$'\n'

$prefix mkdir -p $RAMDISK
$prefix mount -t tmpfs -o size=512M tmpfs $RAMDISK
$prefix chown $USER:$USER $RAMDISK -R

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

    filelist=()
    for line in $(7z l -ba "$archivefile" | grep -vF 'D....' | grep -oP '(?<=^.{53}).*'); do
        filelist+=("$line")
    done
    if [ -z "${#filelist[@]}" ]; then
        continue
    fi

    for ((fileno = 0; fileno < ${#filelist[@]}; fileno++)); do
        trap controlc SIGINT
        onefile="${filelist[$fileno]}"
        # filename="${onefile##*/}"
        basename="$(dirname $onefile)"
        echo -n "."
        mkdir -p "$RAMDISK/${basename}"
        #7z x -so "$archivefile" "$onefile" >"$RAMDISK/$onefile"
        7z x "$archivefile" -o"$RAMDISK" "$onefile" &>/dev/null
        if [ ! -f "$tarfile" ]; then
            tar --create --file="$tarfile" -C "$RAMDISK" "$onefile"
        else
            tar --append --file="$tarfile" -C "$RAMDISK" "$onefile"
        fi
        $prefix rm "$RAMDISK/$onefile"
    done

    echo -ne "\ntesting $tarfile..."
    tar -tf "$tarfile" &>/dev/null
    if [ ! $? -eq 0 ]; then
        echo "created $tarfile is damaged, status: $?"
        exit 1
    fi
    echo "OK"
done

$prefix umount $RAMDISK
#$prefix rmdir $RAMDISK
