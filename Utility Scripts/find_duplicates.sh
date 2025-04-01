#!/bin/bash

# Function to calculate a hash for a folder
hash_folder() {
    local folder="$1"
    (
        cd "$folder" || exit
        # Find all files, sort them, and calculate their hashes
        find . -type f -exec md5sum {} + | sort -k 2 | md5sum | awk '{print $1}'
    )
}

# Main logic to find duplicate folders
find_duplicate_folders() {
    local source_path="$1"

    if [[ ! -d "$source_path" ]]; then
        echo "The provided path does not exist or is not a directory."
        exit 1
    fi

    declare -A folder_hashes
    declare -A duplicate_folders

    # Recursively list all folders
    while IFS= read -r -d '' folder; do
        folder_hash=$(hash_folder "$folder")
        if [[ -n "${folder_hashes[$folder_hash]}" ]]; then
            duplicate_folders["$folder_hash"]+="$folder"$'\n'
        else
            folder_hashes["$folder_hash"]="$folder"
        fi
    done < <(find "$source_path" -type d -print0)

    # Print duplicate folders
    if [[ ${#duplicate_folders[@]} -eq 0 ]]; then
        echo "No duplicate folders found."
    else
        echo "Duplicate folders found:"
        for hash in "${!duplicate_folders[@]}"; do
            echo -e "\nHash: $hash"
            echo -e "${duplicate_folders[$hash]}"
        done
    fi
}

# Run the script directly in the terminal
read -p "Enter the source path to check for duplicate folders: " source_path
find_duplicate_folders "$source_path"
