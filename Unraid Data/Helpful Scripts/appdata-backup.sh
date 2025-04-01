#!/bin/bash

# === Configuration ===

# Source directory to back up (standard Unraid appdata location)
# IMPORTANT: Ensure this ends with a trailing slash /
SOURCE_DIR="/mnt/user/appdata/"

# Base directory where backup files will be stored
# IMPORTANT: Choose a location OUTSIDE of your appdata folder!
#            This could be on the array (e.g., /mnt/user/backups/)
#            or on an unassigned device (e.g., /mnt/disks/backup_drive/)
#            Ensure this ends with a trailing slash /
BACKUP_BASE_DIR="/mnt/user/unraid_appdata_docker/"

# Subdirectory within BACKUP_BASE_DIR specifically for these appdata backups
BACKUP_SUBDIR="appdata_backups"

# Full path to the backup destination directory
# Ensure this ends with a trailing slash /
BACKUP_DIR="${BACKUP_BASE_DIR}${BACKUP_SUBDIR}/"

# Timestamp format for backup filenames (YYYY-MM-DD_HHMMSS)
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")

# Backup filename format
BACKUP_FILENAME="appdata_backup_${TIMESTAMP}.tar.gz"

# Full path for the new backup file
BACKUP_FULL_PATH="${BACKUP_DIR}${BACKUP_FILENAME}"

# Log file location (optional, leave empty "" to disable logging to file)
# A monthly log file will be created in the BACKUP_DIR
LOG_FILE="${BACKUP_DIR}backup_log_$(date +"%Y-%m").log"
# Set LOG_FILE="" to only output to console/User Scripts log viewer

# Number of days to keep backups. Set to 0 to disable rotation.
DAYS_TO_KEEP=14

# === End Configuration ===

# --- Script Variables ---
declare -a stopped_container_ids # Array to hold IDs of containers stopped by this script
backup_status=1 # 0 for success, 1 for initial/failure state

# --- Helper Function for Logging ---
log_message() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${timestamp} - ${message}" # Always echo to stdout (for User Scripts plugin log)
    if [[ -n "$LOG_FILE" ]]; then
        # Ensure log directory exists before trying to write
        mkdir -p "$(dirname "$LOG_FILE")"
        echo "${timestamp} - ${message}" >> "$LOG_FILE"
    fi
}

# --- Pre-run Checks ---
log_message "===== Starting Appdata Backup Script ====="
log_message "Current time: $(date)"

# 0. Check if docker command exists
if ! command -v docker &> /dev/null; then
    log_message "ERROR: 'docker' command not found. Cannot manage containers. Aborting."
    exit 1
fi

# 1. Check if Source Directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "ERROR: Source directory '$SOURCE_DIR' not found. Please check the path. Aborting."
    exit 1
fi

# 2. Check/Create Base Backup Directory
if [ ! -d "$BACKUP_BASE_DIR" ]; then
    log_message "INFO: Base backup directory '$BACKUP_BASE_DIR' not found. Attempting to create..."
    mkdir -p "$BACKUP_BASE_DIR"
    if [ $? -ne 0 ]; then
        log_message "ERROR: Failed to create base backup directory '$BACKUP_BASE_DIR'. Check path and permissions. Aborting."
        echo "$(date +"%Y-%m-%d %H:%M:%S") - ERROR: Failed to create base backup directory '$BACKUP_BASE_DIR'. Check path and permissions. Aborting." >&2
        exit 1
    else
         log_message "INFO: Base backup directory created successfully."
    fi
fi

# 3. Check/Create Specific Backup Directory
 if [ ! -d "$BACKUP_DIR" ]; then
    log_message "INFO: Backup directory '$BACKUP_DIR' not found. Attempting to create."
    mkdir -p "$BACKUP_DIR"
    if [ $? -ne 0 ]; then
         log_message "ERROR: Failed to create backup directory '$BACKUP_DIR'. Check permissions. Aborting."
         exit 1
    else
        log_message "INFO: Backup directory created successfully."
    fi
fi

# --- Docker Container Management (Stop) ---
log_message "Identifying running Docker containers..."
# Use mapfile (bash 4+) for safer reading of command output into an array
# Gets IDs of containers that are currently 'running'
mapfile -t running_container_ids < <(docker ps --filter status=running --format "{{.ID}}")

if [ $? -ne 0 ]; then
    log_message "ERROR: Failed to list running Docker containers. Check Docker daemon status. Aborting stop/start process, proceeding with backup only."
    # Clear the array just in case partial data was read
    unset running_container_ids
    declare -a running_container_ids
else
    # Only proceed if docker ps was successful
    if [ ${#running_container_ids[@]} -eq 0 ]; then
        log_message "No running containers found to stop."
    else
        log_message "Found ${#running_container_ids[@]} running container(s). Attempting to stop them..."
        stopped_container_ids=() # Initialize the array of containers we actually stop
        for container_id in "${running_container_ids[@]}"; do
            container_name=$(docker ps --filter "id=$container_id" --format "{{.Names}}" | head -n 1) # Get name for logging
            log_message "Stopping container: $container_name (ID: $container_id)..."
            docker stop "$container_id"
            if [ $? -eq 0 ]; then
                log_message "Successfully stopped container: $container_name (ID: $container_id)"
                stopped_container_ids+=("$container_id") # Add to our list of successfully stopped containers
            else
                log_message "WARNING: Failed to stop container: $container_name (ID: $container_id). It might interfere with the backup. Continuing..."
                # We do NOT add it to stopped_container_ids, so we don't try to restart it later
            fi
        done
        if [ ${#stopped_container_ids[@]} -gt 0 ]; then
             log_message "Finished stopping ${#stopped_container_ids[@]} container(s)."
             # Optional: Add a short pause to allow containers to fully release files
             # log_message "Pausing briefly..."
             # sleep 5
        else
             log_message "No containers were successfully stopped."
        fi
    fi
fi

# --- Main Backup Logic ---
log_message "Starting backup process..."
log_message "Source: $SOURCE_DIR"
log_message "Destination: $BACKUP_FULL_PATH"
log_message "Log File: ${LOG_FILE:-'Console Only'}"

# Create the compressed archive using tar
log_message "Creating compressed archive (tar)..."
tar -czvf "$BACKUP_FULL_PATH" -C "$SOURCE_DIR" .

# Check the exit status of the tar command
if [ $? -eq 0 ]; then
    backup_status=0 # Set status to success
    log_message "SUCCESS: Backup archive created successfully: $BACKUP_FULL_PATH"
    if command -v du &> /dev/null; then
        backup_size=$(du -sh "$BACKUP_FULL_PATH" | cut -f1)
        log_message "Backup Size: $backup_size"
    fi
else
    backup_status=1 # Ensure status is failure
    log_message "ERROR: tar command failed with exit code $?. Backup may be incomplete or corrupted."
    log_message "Attempting to remove potentially incomplete file: $BACKUP_FULL_PATH"
    rm -f "$BACKUP_FULL_PATH"
    # Do NOT exit here - proceed to restart containers
fi

# --- Docker Container Management (Start) ---
if [ ${#stopped_container_ids[@]} -eq 0 ]; then
    log_message "No containers were stopped by this script, skipping restart phase."
else
    log_message "Restarting ${#stopped_container_ids[@]} container(s) that were stopped by this script..."
    for container_id in "${stopped_container_ids[@]}"; do
        container_name=$(docker ps -a --filter "id=$container_id" --format "{{.Names}}" | head -n 1) # Get name even if stopped
        log_message "Starting container: $container_name (ID: $container_id)..."
        docker start "$container_id"
        if [ $? -ne 0 ]; then
            log_message "WARNING: Failed to start container: $container_name (ID: $container_id). Check container logs/status manually."
        else
            log_message "Successfully started container: $container_name (ID: $container_id)"
        fi
    done
    log_message "Finished restarting containers."
fi

# --- Backup Rotation (only run if backup was successful) ---
if [ $backup_status -eq 0 ]; then
    if [ "$DAYS_TO_KEEP" -gt 0 ]; then
        log_message "Running backup rotation. Keeping the last $DAYS_TO_KEEP days of backups in '$BACKUP_DIR'..."
        log_message "Searching for backups older than $DAYS_TO_KEEP days to delete..."
        # Enclose find command in subshell and capture output/errors for better logging
        rotation_output=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'appdata_backup_*.tar.gz' -mtime "+$(($DAYS_TO_KEEP - 1))" -print -delete 2>&1)
        find_exit_code=$?
        if [[ -n "$rotation_output" ]]; then
             log_message "Rotation Output:"$'\n'"$rotation_output" # Log output from find command
        fi

        if [ $find_exit_code -eq 0 ]; then
            if [[ -z "$rotation_output" ]]; then
                 log_message "No old backups found to delete."
            else
                 log_message "Old backup cleanup finished successfully."
            fi
        else
            log_message "WARNING: Backup cleanup command finished with exit code $find_exit_code. Issues may have occurred (check rotation output above)."
        fi
    else
        log_message "INFO: Backup rotation is disabled (DAYS_TO_KEEP set to 0 or less)."
    fi
else
     log_message "Skipping backup rotation because the main backup process failed."
fi

# --- Final Status ---
if [ $backup_status -eq 0 ]; then
    log_message "===== Backup Script Finished Successfully ====="
else
    log_message "===== Backup Script Finished with Errors ====="
fi

echo "" # Add a blank line to log for readability between runs

exit $backup_status # Exit with 0 on success, 1 on failure