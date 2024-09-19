#!/bin/bash -x

controlc() {
    exit 1
}

SOURCE_ARCHIVES=$1
MOUNT_DESTINATION=$2
SKIPKEYWORD=".ipynb_checkpoints"

#checks
if [ -z "$SOURCE_ARCHIVES" ] || [ -z "$MOUNT_DESTINATION" ]; then
    echo "Usage: $0 <SOURCE_ARCHIVES> <MOUNT_DESTINATION>"
    echo "Universal example: $0 /mnt/sams2T_crypt_vg_data/datasets ./source_datasets"
    exit 1
fi
if [ ! -d "$MOUNT_DESTINATION" ]; then
    mkdir -p "$MOUNT_DESTINATION"
fi
if [ ! -d "$MOUNT_DESTINATION" ]; then
    echo "Failed to create $MOUNT_DESTINATION"
    exit 1
fi

if [ ! -d "$SOURCE_ARCHIVES" ]; then
    echo "No such directory: $SOURCE_ARCHIVES"
    exit 1
fi

#list archives
declare -a archivefiles
IFS=$'\n'
for line in $(find "$SOURCE_ARCHIVES" -type f -name "*.tar" 2>/dev/null | sort -n); do
    archivefiles+=("$line")
done
echo "archive count: ${#archivefiles[@]}"
echo "${archivefiles[@]}"

# list mounts
declare -a alldirs
IFS=$'\n'
for line in $(find "$MOUNT_DESTINATION" -maxdepth 1 -type d 2>/dev/null | grep -v "$SKIPKEYWORD" | grep -v "^\.$" | grep -v "^\.\.$" | sort -n); do
    alldirs+=("$line")
done
alldirs=("${alldirs[@]:1}")
echo "mount points to unmount: ${#alldirs[@]}"
echo "${alldirs[@]}"

echo "press [m] to mount, [u] to unmount, [q] to quit"
while true; do
    read -n 1 -s -r -p "" key
    case $key in
    m)
        # mount
        for ((i = 0; i < ${#archivefiles[@]}; i++)); do
            basename="${archivefiles[$i]##*/}"
            ratarmount "${archivefiles[$i]}" "$MOUNT_DESTINATION/${basename}"
        done
        exit 0
        ;;
    u)
        # unmount
        for onedir in "${alldirs[@]}"; do
            trap controlc SIGINT
            echo "Unmounting $onedir..."
            ratarmount -u "$onedir"
        done
        exit 0
        ;;
    q)
        exit 0
        ;;
    esac
done
