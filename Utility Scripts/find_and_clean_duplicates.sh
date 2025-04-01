#!/bin/bash

# Script to keep the first instance of duplicate folder names (matching only the part before '(') 
# and delete the others.
# Usage: ./find_duplicate_folders.sh /path/to/source

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <source-path>"
    exit 1
fi

SOURCE_PATH=$1

# Check if the given path exists and is a directory
if [ ! -d "$SOURCE_PATH" ]; then
    echo "Error: $SOURCE_PATH is not a valid directory."
    exit 1
fi

echo "Scanning for duplicate folder names (before '(') in: $SOURCE_PATH"

# Find all directories, extract their base names, truncate before '(' if present, and sort them
declare -A folder_map

find "$SOURCE_PATH" -type d -print0 | 
while IFS= read -r -d '' dir; do
    folder_name=$(basename "$dir" | awk -F '(' '{print $1}')
    if [[ -z "${folder_map[$folder_name]}" ]]; then
        # If the folder name isn't in the map, add it
        folder_map[$folder_name]="$dir"
    else
        # If it is, delete the duplicate
        echo "Deleting duplicate folder: $dir"
        rm -rf "$dir"
    fi
done

echo "Duplicate folders removed. First instances retained."
