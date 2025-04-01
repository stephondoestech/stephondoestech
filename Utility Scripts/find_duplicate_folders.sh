#!/bin/bash

# Script to list duplicate folder names in a given source path
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

echo "Scanning for duplicate folder names in: $SOURCE_PATH"

# Find all directories, extract their base names, sort them, and count occurrences
find "$SOURCE_PATH" -type d -print0 | 
xargs -0 -n1 basename | 
sort | 
uniq -d > duplicate_folder_names.txt

# Check if any duplicates were found
if [ -s duplicate_folder_names.txt ]; then
    echo "Duplicate folder names found:"
    while IFS= read -r folder; do
        echo "$folder"
        # Find all occurrences of the duplicate folder
        find "$SOURCE_PATH" -type d -name "$folder"
    done < duplicate_folder_names.txt
else
    echo "No duplicate folder names found."
fi

# Clean up temporary file
rm -f duplicate_folder_names.txt
