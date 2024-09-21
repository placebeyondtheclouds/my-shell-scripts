#!/bin/bash

controlc() {
    exit 1
}

ARCHIVE_DESTINATION=${1:-.}
SKIPKEYWORD=".ipynb_checkpoints"

# check destination
if [ ! -d "$ARCHIVE_DESTINATION" ]; then
    read -p "Destination $ARCHIVE_DESTINATION does not exist. Create it? [y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$ARCHIVE_DESTINATION"
    else
        echo "Exiting..."
        exit 1
    fi
fi

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
    if [ -f "$ARCHIVE_DESTINATION/$onedir.tar" ]; then
        rm -f "$ARCHIVE_DESTINATION/$onedir.tar"
    fi
    onedir=$(basename "$onedir")
    tar -cf "$ARCHIVE_DESTINATION/$onedir.tar" "$onedir"

done

# list archives
# declare -a archivefiles
# IFS=$'\n'
# for line in $(find "$ARCHIVE_DESTINATION" -type f -name "*.tar" 2>/dev/null | sort -n); do
#     archivefiles+=("$line")
# done

# test
# for onearchive in "${archivefiles[@]}"; do
#     trap controlc SIGINT
#     echo -n "Testing $onearchive..."
#     tar -tf "$onearchive" >/dev/null 2>&1
#     if [ $? -ne 0 ]; then
#         echo -e "\n File $onearchive is corrupted" | tee -a archiveswitherrors.txt
#     else
#         echo -n "."
#     fi
# done

# merge
# firstarchive=${archivefiles[0]}
# for ((i = 1; i < ${#archivefiles[@]}; i++)); do
#     if [ $(tar -tf "${archivefiles[$i]}" | wc -l) -eq 0 ]; then
#         echo "del empty: ${archivefiles[$i]}"
#         rm "${archivefiles[$i]}"
#         continue
#     fi
#     tar -Af "$firstarchive" "${archivefiles[$i]}"
#     rm -f "${archivefiles[$i]}"
# done
# mv "$firstarchive" "merged.tar"
# echo "chunks in the archive:" $(tar -tf "merged.tar" | wc -l)

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
