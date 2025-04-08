#!/bin/bash

# === Configuration ===

# IMPORTANT: Set this to the EXACT directory where SABnzbd stores its backups.
# Check your SABnzbd settings: Config -> Folders -> Backup Folder
# Common Unraid paths:
#   /mnt/user/appdata/sabnzbd/admin/backup/
#   /mnt/user/appdata/sabnzbd/backup/
#   Or a custom path if you configured one.
# Ensure this ends with a trailing slash / unless it's the root of a drive/share.
BACKUP_DIR="/mnt/user/data/usenet/backup"

# Number of days AFTER which backups should be deleted (e.g., 14 means delete backups older than 14 days)
AGE_DAYS=14

# Filename pattern to match SABnzbd backups.
# Use standard shell globbing patterns.
# Examples:
#   'sabnzbd-backup-*.zip' (Recommended default for SABnzbd)
#   '*.zip' (If ONLY sabnzbd backups are in this directory)
FILENAME_PATTERN='sabnzbd_backup_*.zip'

# Dry Run Mode: Set to "true" to only list files that WOULD be deleted.
# Set to "false" to actually delete the files.
# >>> ALWAYS RUN WITH "true" FIRST TO VERIFY! <<<
DRY_RUN="true"

# Log file location (optional, leave empty "" to disable logging to file)
# A monthly log file can be created (e.g., in a dedicated log dir)
# Example: LOG_FILE="/mnt/user/backups/logs/sabnzbd_cleanup_$(date +"%Y-%m").log"
# Example: LOG_FILE="${BACKUP_DIR}../cleanup_log_$(date +"%Y-%m").log" # Log in parent dir
LOG_FILE="" # Set path or leave empty for console/User Scripts log only

# === End Configuration ===

# --- Helper Function for Logging ---
log_message() {
    local message="$1"
    # Using ISO 8601 format for timestamp
    local timestamp=$(date --iso-8601=seconds)
    echo "${timestamp} - ${message}" # Always echo to stdout (for User Scripts log)
    if [[ -n "$LOG_FILE" ]]; then
        # Ensure log directory exists before trying to write
        mkdir -p "$(dirname "$LOG_FILE")"
        echo "${timestamp} - ${message}" >> "$LOG_FILE"
    fi
}

# --- Pre-run Checks ---
log_message "===== Starting SABnzbd Old Backup Cleanup Script ====="
log_message "Backup Directory: $BACKUP_DIR"
log_message "Delete files older than: $AGE_DAYS days"
log_message "Filename Pattern: $FILENAME_PATTERN"
log_message "Dry Run Mode: $DRY_RUN"
log_message "Log File: ${LOG_FILE:-'Console/UserScripts Only'}"

# Validate Backup Directory
if [ ! -d "$BACKUP_DIR" ]; then
    log_message "ERROR: Backup directory '$BACKUP_DIR' not found. Please verify the path in the script configuration. Aborting."
    exit 1
fi

# Validate AGE_DAYS
if ! [[ "$AGE_DAYS" =~ ^[0-9]+$ ]] || [ "$AGE_DAYS" -le 0 ]; then
    log_message "ERROR: AGE_DAYS ('$AGE_DAYS') must be a positive integer. Aborting."
    exit 1
fi

# Calculate mtime parameter for find command
# -mtime +N finds files modified *more* than N*24 hours ago.
# So, for "older than 14 days", we need files modified more than 13 days ago.
mtime_val=$(($AGE_DAYS - 1))
if [ "$mtime_val" -lt 0 ]; then
     # Should not happen with validation above, but safety check
     mtime_val=0
fi
log_message "Using find -mtime parameter: +$mtime_val"

# --- Main Cleanup Logic ---
log_message "Searching for files matching '$FILENAME_PATTERN' in '$BACKUP_DIR' modified more than $mtime_val days ago..."

# Construct the base find command arguments in an array for safety
find_cmd_args=(
    "$BACKUP_DIR"        # Path to search
    -maxdepth 1          # Do not search subdirectories
    -type f              # Only find files
    -name "$FILENAME_PATTERN" # Match the filename pattern
    -mtime "+$mtime_val"   # Match files older than AGE_DAYS
)

# Determine the action based on DRY_RUN setting
if [[ "$DRY_RUN" == "true" ]]; then
    log_message "DRY RUN: Finding files that WOULD be deleted (no changes will be made):"
    find_cmd_args+=("-print") # Action: just print the found filenames
    action_desc="Dry run found"
    error_desc="Dry run search failed"
else
    log_message "WARNING: ACTUAL DELETION ENABLED. Files listed below will be deleted."
    # Action: print the filename, then delete it. -print is useful for logging.
    find_cmd_args+=("-print" "-delete")
    action_desc="Deleted"
    error_desc="Deletion process failed"
fi

# Execute the find command and capture output/errors
# Using process substitution and mapfile is safer than direct command substitution for multi-line output
declare -a found_files
mapfile -t found_files < <(find "${find_cmd_args[@]}" 2>&1)
find_exit_code=$?

# Check find command results
if [ $find_exit_code -eq 0 ]; then
    if [ ${#found_files[@]} -gt 0 ]; then
        log_message "$action_desc the following files (${#found_files[@]} total):"
        # Print each found/deleted file for clarity in the log
        printf "  %s\n" "${found_files[@]}" | while IFS= read -r line; do log_message "  $line"; done
    else
        log_message "No matching files found older than $AGE_DAYS days."
    fi
    log_message "Cleanup process finished successfully."
    final_exit_code=0
else
    # find command failed
    log_message "ERROR: The 'find' command failed with exit code $find_exit_code."
    if [ ${#found_files[@]} -gt 0 ]; then
        log_message "$error_desc. Error details/output:"
        printf "  %s\n" "${found_files[@]}" | while IFS= read -r line; do log_message "  $line"; done
    else
         log_message "$error_desc. No specific error output captured."
    fi
    log_message "Cleanup process finished with errors."
    final_exit_code=1
fi

log_message "===== SABnzbd Cleanup Script Finished ====="
echo "" # Add a blank line to log for readability between runs

exit $final_exit_code