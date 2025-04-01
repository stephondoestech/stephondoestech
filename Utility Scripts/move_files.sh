#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 <source_directory> <target_directory>"
    exit 1
}

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
    usage
fi

SOURCE_DIR="$1"
TARGET_DIR="$2"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
fi

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    echo "Created target directory: $TARGET_DIR"
fi

# Function to move files recursively
move_files() {
    local source="$1"
    for file in "$source"/*; do
        if [ -f "$file" ]; then
            # Extract file name and extension
            base_name=$(basename "$file")
            target_file="$TARGET_DIR/$base_name"

            # Ensure unique file name in the target directory
            counter=1
            while [ -e "$target_file" ]; do
                target_file="$TARGET_DIR/${base_name%.*}_$counter.${base_name##*.}"
                counter=$((counter + 1))
            done

            # Move the file
            mv "$file" "$target_file"
            echo "Moved: $file -> $target_file"
        elif [ -d "$file" ]; then
            # Recursively process directories
            move_files "$file"
        fi
    done
}

# Start moving files
move_files "$SOURCE_DIR"
echo "All files moved successfully!"
