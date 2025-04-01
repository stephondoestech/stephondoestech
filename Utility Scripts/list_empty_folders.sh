#!/bin/bash

# Check if the source path is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <source_path>"
    exit 1
fi

# Source path
SOURCE_PATH="$1"

# Check if the provided path exists
if [ ! -d "$SOURCE_PATH" ]; then
    echo "Error: $SOURCE_PATH is not a valid directory."
    exit 1
fi

# Function to recursively find and print empty directories
find_empty_folders() {
    local path="$1"

    # Iterate over all items in the directory
    for item in "$path"/*; do
        if [ -d "$item" ]; then
            # Recursively check subdirectories
            find_empty_folders "$item"
        fi
    done

    # Check if the directory is empty
    if [ -z "$(ls -A "$path")" ]; then
        echo "Empty folder: $path"
    fi
}

# Start the search from the source path
find_empty_folders "$SOURCE_PATH"
