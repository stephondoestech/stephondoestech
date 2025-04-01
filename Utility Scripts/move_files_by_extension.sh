#!/bin/bash

# Define the directory to search and the destination directory
SEARCH_DIR=$1   # First argument: directory to search
DEST_DIR=$2     # Second argument: destination directory
EXTENSIONS=$3   # Third argument: comma-separated list of extensions (e.g., "jpg,png,txt")

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Convert the comma-separated extensions to a pipe-separated regex pattern
PATTERN=$(echo "$EXTENSIONS" | sed 's/,/\\|/g')

# Find and move files matching the extensions
find "$SEARCH_DIR" -type f -regex ".*\.\($PATTERN\)$" -exec mv {} "$DEST_DIR" \;

echo "Files with extensions ($EXTENSIONS) have been moved to $DEST_DIR"
