#!/bin/bash

controlc() {
    exit 1
}

echo "Test if ratarmount is installed..."
if ! ratarmount -v; then
    echo -e "\n\n\nratarmount not found. activate conda environment with ratarmount installed first or install it with \nconda install -c conda-forge ratarmount \nor\npip install ratarmount\nquitting."
    exit 1
fi

SOURCE_ARCHIVES=$1
MOUNT_DESTINATION=$2
SKIPKEYWORD=".ipynb_checkpoints"

declare -a archivefiles
declare -a alldirs

cat <<"EOF"
                                     __                                     ______  ______   ____               
 /'\_/`\                           /\ \__                                 /\__  _\/\  _  \ /\  _`\             
/\      \     ___    __  __    ___ \ \ ,_\        ___    __  __   _ __    \/_/\ \/\ \ \L\ \\ \ \L\ \     ____  
\ \ \__\ \   / __`\ /\ \/\ \ /' _ `\\ \ \/       / __`\ /\ \/\ \ /\`'__\     \ \ \ \ \  __ \\ \ ,  /    /',__\ 
 \ \ \_/\ \ /\ \L\ \\ \ \_\ \/\ \/\ \\ \ \_     /\ \L\ \\ \ \_\ \\ \ \/       \ \ \ \ \ \/\ \\ \ \\ \  /\__, `\
  \ \_\\ \_\\ \____/ \ \____/\ \_\ \_\\ \__\    \ \____/ \ \____/ \ \_\        \ \_\ \ \_\ \_\\ \_\ \_\\/\____/
   \/_/ \/_/ \/___/   \/___/  \/_/\/_/ \/__/     \/___/   \/___/   \/_/         \/_/  \/_/\/_/ \/_/\/ / \/___/ 
  
EOF

#checks
if [ -z "$SOURCE_ARCHIVES" ] || [ -z "$MOUNT_DESTINATION" ]; then
    echo "Usage: $0 <SOURCE_ARCHIVES> <MOUNT_DESTINATION>"
    echo "Universal example: $0 /mnt/sams2T_crypt_vg_data/datasets ./source_datasets [--recursive]"
    echo "Quitting."
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

list_archives() {
    local SOURCE_ARCHIVES=$1
    #this is a dictionary hahaha, associative array
    declare -A archivefiles_map
    IFS=$'\n'

    mapfile -t files < <(find "$SOURCE_ARCHIVES" -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.tar.gz" \) 2>/dev/null | sort -n)
    for line in "${files[@]}"; do
        case "$line" in
        *.tar.gz)
            base_name="${line%.tar.gz}"
            ;;
        *.tar)
            base_name="${line%.tar}"
            ;;
        *)
            base_name="${line%.*}"
            ;;
        esac
        if [ -d "$base_name" ]; then
            continue
        fi
        if [[ "$line" == *.tar ]]; then
            archivefiles_map["$base_name"]="$line"
        else
            if [[ -z "${archivefiles_map[$base_name]}" ]]; then
                archivefiles_map["$base_name"]="$line"
            fi
        fi
    done
    archivefiles=("${archivefiles_map[@]}")

    cat <<"EOF"
   _    ___   ___  _  _  ___ __   __ ___  ___     __                      _  _ 
  /_\  | _ \ / __|| || ||_ _|\ \ / /| __|/ __|   / _| ___  _  _  _ _   __| |(_)
 / _ \ |   /| (__ | __ | | |  \ V / | _| \__ \  |  _|/ _ \| || || ' \ / _` | _ 
/_/ \_\|_|_\ \___||_||_||___|  \_/  |___||___/  |_|  \___/ \_,_||_||_|\__,_|(_)
                                                                                                                                                          
EOF
    echo "archive count: ${#archivefiles[@]}"
    for file in "${archivefiles[@]}"; do
        echo "$file"
    done
}

list_mounts() {
    local MOUNT_DESTINATION=$1
    local SKIPKEYWORD=$2
    alldirs=()
    IFS=$'\n'
    for line in $(find "$MOUNT_DESTINATION" -maxdepth 1 -type d 2>/dev/null | grep -v "$SKIPKEYWORD" | grep -v "^\.$" | grep -v "^\.\.$" | sort -n); do
        alldirs+=("$line")
    done

    # remove first element
    alldirs=("${alldirs[@]:1}")

    # remove empty dir and the item from array
    for onedir in "${alldirs[@]}"; do
        if [[ -d "$onedir" ]]; then
            if [[ -z "$(ls -A "$onedir")" ]]; then
                rm -rf "$onedir"
                alldirs=("${alldirs[@]/$onedir/}")
            fi
        fi
    done
    cat <<"EOF"
                        _          __                      _  _ 
 _ __   ___  _  _  _ _ | |_  ___  / _| ___  _  _  _ _   __| |(_)
| '  \ / _ \| || || ' \|  _|(_-< |  _|/ _ \| || || ' \ / _` | _ 
|_|_|_|\___/ \_,_||_||_|\__|/__/ |_|  \___/ \_,_||_||_|\__,_|(_)
                                                                        
EOF
    echo "mount points to unmount (or empty dirs deleted): ${#alldirs[@]}"
    for dir in "${alldirs[@]}"; do
        echo "$dir"
    done
}

list_archives "$SOURCE_ARCHIVES"
list_mounts "$MOUNT_DESTINATION" "$SKIPKEYWORD"

while true; do
    cat <<"EOF"
    
            Oo               Oo             
           o  O             o  O            
          O    o           O    o           
ooooooooo                         ooooooooo 
                                            
ooooooooo                         ooooooooo 
                                            
                                            
                 ooooooooo                  
                                                                                                                 
EOF
    echo "press [m] to mount, [u] to unmount, [q] to quit"
    read -n 1 -s -r -p "" key

    case $key in
    m)
        # mount
        for ((i = 0; i < ${#archivefiles[@]}; i++)); do
            basename="${archivefiles[$i]##*/}"
            destination="$MOUNT_DESTINATION/${basename}"

            if [ -e "$destination" ]; then
                echo "Skipping ${basename}, its already mounted in $destination"
                read -n 1 -s -r -p "Press any key to continue"
            else
                if [ "$3" == "--recursive" ]; then
                    ratarmount --recursive "${archivefiles[$i]}" "$destination"
                else
                    ratarmount "${archivefiles[$i]}" "$destination"
                fi
            fi
        done
        list_archives "$SOURCE_ARCHIVES"
        list_mounts "$MOUNT_DESTINATION" "$SKIPKEYWORD"
        ;;
    u)
        # unmount
        for onedir in "${alldirs[@]}"; do
            trap controlc SIGINT
            echo "Unmounting $onedir..."
            ratarmount -u "$onedir"
            if [[ -d "$onedir" ]]; then
                if [[ -z "$(ls -A "$onedir")" ]]; then
                    rm -rf "$onedir"
                fi
            fi
        done
        list_archives "$SOURCE_ARCHIVES"
        list_mounts "$MOUNT_DESTINATION" "$SKIPKEYWORD"
        ;;
    q)
        exit 0
        ;;
    esac
done
