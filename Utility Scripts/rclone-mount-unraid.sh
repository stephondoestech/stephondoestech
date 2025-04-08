#!/bin/bash
# rclone-mount-unraid.sh
# Script to mount Unraid shares on macOS using official rclone binaries

#./rclone-mount-unraid.sh mount to mount shares
#./rclone-mount-unraid.sh unmount to unmount shares
#./rclone-mount-unraid.sh autostart to create a launchd plist for auto-mounting at login
#diskutil unmount force /path/to/mount to force unmount if needed

# Exit on error
set -e

# Configuration variables - modify these as needed
UNRAID_IP="192.168.50.2"  # Unraid server IP 
UNRAID_USER="sgparker"
UNRAID_SHARES=("data" "drive" "drive-stephon" "entropy-vault")  # share names
LOCAL_MOUNT_BASE="$HOME/Hogsmeade Shares"
RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
LOG_FILE="$HOME/Library/Logs/rclone-mount.log"

# Path to official rclone binary - change this if your installation location differs
RCLONE_BIN="/usr/local/bin/rclone"

# Create mount base directory if it doesn't exist
mkdir -p "$LOCAL_MOUNT_BASE"
mkdir -p "$(dirname "$LOG_FILE")"

# Function to check if official rclone is installed
check_rclone() {
  if [ ! -f "$RCLONE_BIN" ]; then
    echo "Official rclone binary not found at $RCLONE_BIN"
    echo "Please download it from https://rclone.org/downloads/ and install it"
    echo "Run these commands to install:"
    echo "  curl -O https://downloads.rclone.org/rclone-current-osx-amd64.zip"
    echo "  unzip rclone-current-osx-amd64.zip"
    echo "  cd rclone-*-osx-amd64"
    echo "  sudo cp rclone /usr/local/bin/"
    echo "  sudo chown root:wheel /usr/local/bin/rclone"
    echo "  sudo chmod 755 /usr/local/bin/rclone"
    exit 1
  fi
  
  echo "Using rclone binary: $RCLONE_BIN"
  $RCLONE_BIN version
}

# Function to setup rclone config if not already configured
setup_rclone_config() {
  if [ ! -f "$RCLONE_CONFIG" ] || ! grep -q "\[unraid\]" "$RCLONE_CONFIG"; then
    echo "Setting up rclone configuration for Unraid..."
    mkdir -p "$(dirname "$RCLONE_CONFIG")"
    
    # Create rclone config for Unraid
    cat << EOF >> "$RCLONE_CONFIG"
[unraid]
type = smb
host = $UNRAID_IP
user = $UNRAID_USER
pass = $(security find-generic-password -a "$UNRAID_USER" -s "unraid-smb" -w 2>/dev/null || read -sp "Enter your Unraid password: " PASS && echo "$PASS")
domain = 
EOF
    
    # Store password in macOS keychain for future use if not already stored
    if ! security find-generic-password -a "$UNRAID_USER" -s "unraid-smb" &>/dev/null; then
      security add-generic-password -a "$UNRAID_USER" -s "unraid-smb" -w "$(grep "pass = " "$RCLONE_CONFIG" | cut -d' ' -f3-)"
      # Remove password from config file for security
      sed -i '' 's/pass = .*/pass = /' "$RCLONE_CONFIG"
    fi
    
    echo "Rclone configuration created."
  fi
}

# Function to mount the Unraid shares
mount_shares() {
  # Kill any existing rclone processes
  pkill -f "$RCLONE_BIN mount" || true
  
  for SHARE in "${UNRAID_SHARES[@]}"; do
    MOUNT_POINT="$LOCAL_MOUNT_BASE/$SHARE"
    
    # Create local mount point if it doesn't exist
    mkdir -p "$MOUNT_POINT"
    
    # Check if already mounted
    if mount | grep -q "$MOUNT_POINT"; then
      echo "Share $SHARE is already mounted at $MOUNT_POINT"
    else
      echo "Mounting $SHARE to $MOUNT_POINT..."
      
      # Mount the share with official rclone binary
      $RCLONE_BIN mount \
        --vfs-cache-mode full \
        --vfs-cache-max-size 1G \
        --dir-cache-time 24h \
        --cache-dir "$HOME/.cache/rclone" \
        --log-file "$LOG_FILE" \
        --log-level INFO \
        --allow-other \
        "unraid:$SHARE" "$MOUNT_POINT" &
      
      # Wait for mount to complete
      sleep 2
      
      # Check if mount was successful
      if mount | grep -q "$MOUNT_POINT"; then
        echo "Successfully mounted $SHARE"
      else
        echo "Failed to mount $SHARE. Check the log at $LOG_FILE"
      fi
    fi
  done
}

# Function to create a launchd plist for auto-mounting at login
create_launchd_plist() {
  PLIST_FILE="$HOME/Library/LaunchAgents/com.stephondoestech.rclone-mount.plist"
  
  mkdir -p "$(dirname "$PLIST_FILE")"
  
  cat << EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.stephondoestech.rclone-mount</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(which bash)</string>
        <string>$(realpath "$0")</string>
        <string>mount</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/rclone-mount-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/rclone-mount-stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF
  
  # Unload existing plist if it exists
  launchctl unload "$PLIST_FILE" 2>/dev/null || true
  
  # Load the launchd plist
  launchctl load "$PLIST_FILE"
  
  echo "Created and loaded LaunchAgent for auto-mounting at login."
  echo "Plist file location: $PLIST_FILE"
}

# Function to unmount all shares
unmount_shares() {
  for SHARE in "${UNRAID_SHARES[@]}"; do
    MOUNT_POINT="$LOCAL_MOUNT_BASE/$SHARE"
    
    if mount | grep -q "$MOUNT_POINT"; then
      echo "Unmounting $SHARE from $MOUNT_POINT..."
      umount "$MOUNT_POINT" || diskutil unmount "$MOUNT_POINT" || diskutil unmount force "$MOUNT_POINT"
      
      # Check if unmount was successful
      if ! mount | grep -q "$MOUNT_POINT"; then
        echo "Successfully unmounted $SHARE"
      else
        echo "Failed to unmount $SHARE. You may need to use 'sudo umount -f $MOUNT_POINT'"
      fi
    else
      echo "$SHARE is not currently mounted"
    fi
  done
  
  # Kill any remaining rclone processes
  pkill -f "$RCLONE_BIN mount" || true
  
  echo "All shares unmounted."
}

# Main execution
case "${1:-mount}" in
  mount)
    check_rclone
    setup_rclone_config
    mount_shares
    echo "All shares mounted. Keep this terminal window open to maintain the connection."
    echo "Press Ctrl+C to unmount all shares and exit."
    trap unmount_shares EXIT
    
    # Keep script running to maintain mounts
    while true; do 
      sleep 60
    done
    ;;
  unmount)
    unmount_shares
    ;;
  autostart)
    check_rclone
    create_launchd_plist
    ;;
  *)
    echo "Usage: $0 [mount|unmount|autostart]"
    echo "  mount     - Mount all Unraid shares (default)"
    echo "  unmount   - Unmount all Unraid shares"
    echo "  autostart - Create LaunchAgent for auto-mounting at login"
    exit 1
    ;;
esac

echo "Operation completed."