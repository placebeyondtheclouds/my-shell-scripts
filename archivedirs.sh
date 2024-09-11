#!/bin/bash

controlc() {
    exit 1
}

ARCHIVE_DESTINATION=${1:-.}
SKIPKEYWORD=".ipynb_checkpoints"

# archive
declare -a alldirs
IFS=$'\n'
for line in $(find . -maxdepth 1 -type d 2>/dev/null | grep -v "$SKIPKEYWORD" | grep -v "^\.$" | grep -v "^\.\.$" | sort -n); do
    alldirs+=("$line")
done

echo "dir count: ${#alldirs[@]}"
echo "${alldirs[@]}"
echo "archive to $ARCHIVE_DESTINATION"
read -p "Press enter to continue"
for onedir in "${alldirs[@]}"; do
    trap controlc SIGINT
    echo "Archiving $onedir..."
    onedir=$(basename "$onedir")
    tar -cf "$ARCHIVE_DESTINATION/$onedir.tar" "$onedir"

done

# list archives
declare -a archivefiles
IFS=$'\n'
for line in $(find "$ARCHIVE_DESTINATION" -type f -name "*.tar" 2>/dev/null | sort -n); do
    archivefiles+=("$line")
done

# test
for onearchive in "${archivefiles[@]}"; do
    trap controlc SIGINT
    echo -n "Testing $onearchive..."
    tar -tf "$onearchive" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "\n File $onearchive is corrupted" | tee -a archiveswitherrors.txt
    else
        echo -n "."
    fi
done

#delete dirs
# for onedir in ${alldirs[@]}; do
#     rm -rf "$onedir"
#     echo "Deleting $onedir..."
# done

#extract
# for onearchive in ${archivefiles[@]}; do
#     trap controlc SIGINT
#     tar -xf "$onearchive"
# done

#list the contents of the archive
#tar -tf archive.tar
