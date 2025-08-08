#!/bin/bash

print_message() {
    echo "================================================="
    echo "$1"
    echo "================================================="
}

# Script: encrypt_home_gocryptfs.sh
# Description: Automate the setup of an encrypted home directory using gocryptfs on Arch Linux (Btrfs).
# WARNING: This script will make significant changes to the user home directory.
#          Ensure you have backups and have read the steps before proceeding.

USER_TO_CONVERT="alice"    # <-- Set the target username here (whose home will be encrypted)

# Safety check: Do not proceed if USER_TO_CONVERT is empty or root
if [[ -z "$USER_TO_CONVERT" || "$USER_TO_CONVERT" == "root" ]]; then
    print_message "Error: Invalid target username. Edit the script to set USER_TO_CONVERT." >&2
    exit 1
fi

# Resolve home directory path and ensure it exists
USER_HOME="/home/$USER_TO_CONVERT"
if [[ ! -d "$USER_HOME" ]]; then
    print_message "Error: Home directory $USER_HOME does not exist. Exiting." >&2
    exit 1
fi

# Make sure script is not run from inside the user's home, to allow moving the directory
CURRENT_DIR=$(pwd)
if [[ "$CURRENT_DIR" == "$USER_HOME"* ]]; then
    print_message "Please run this script from outside $USER_HOME (e.g., /root or /tmp) to avoid directory locks."
    exit 1
fi

print_message "This script will migrate $USER_HOME to an encrypted gocryptfs home."
read -rp "Have you backed up important data and are ready to proceed? [y/N]: " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    print_message "Aborting at user request."
    exit 0
fi

# 1. Install required packages (gocryptfs, pam_mount, fuse2) if not already installed
print_message "Installing required packages (gocryptfs, pam_mount, fuse2) if needed..."
pacman -Sy --needed --noconfirm gocryptfs pam_mount fuse2 || {
    print_message "Error: Package installation failed. Ensure you have network connectivity and run pacman manually." >&2; exit 1;
}

# 2. Create and initialize the gocryptfs cipher directory
CIPHER_DIR="/home/.cipher-$USER_TO_CONVERT"
PLAIN_DIR="/home/.plain-$USER_TO_CONVERT"
if [[ -d "$CIPHER_DIR" && -f "$CIPHER_DIR/gocryptfs.conf" ]]; then
    print_message "Notice: Cipher directory $CIPHER_DIR already exists and is initialized (gocryptfs.conf found)."
    SKIP_INIT=true
else
    # Create cipher directory with correct ownership
    mkdir -p "$CIPHER_DIR" || { print_message "Error: Failed to create $CIPHER_DIR"; exit 1; }
    chown "$USER_TO_CONVERT":"$USER_TO_CONVERT" "$CIPHER_DIR"
    print_message "Created cipher directory: $CIPHER_DIR (owner set to $USER_TO_CONVERT)."

    # Disable CoW on cipher directory (Btrfs specific)
    chattr +C "$CIPHER_DIR" 2>/dev/null && print_message "Disabled Copy-on-Write on $CIPHER_DIR (chattr +C set)." || echo "Warning: Could not set +C attribute (Copy-on-Write) on $CIPHER_DIR."

    # Initialize gocryptfs (will prompt for password)
    print_message "Initializing gocryptfs filesystem at $CIPHER_DIR..."
    print_message "Choose a strong password for encryption (ideally the same as the login password for PAM integration)."
    # Use -extpass to read from stdin to capture master key output
    GOC_INIT_OUTPUT=$(gocryptfs -extpass "read -s -p 'New password: ' PASS; print_message \$PASS" -init "$CIPHER_DIR" 2>&1)
    EXIT_CODE=$?
    print_message ""  # ensure a newline after password prompt
    if [[ $EXIT_CODE -ne 0 ]]; then
        print_message "Error: gocryptfs initialization failed. Output:" >&2
        print_message "$GOC_INIT_OUTPUT" >&2
        exit 1
    fi
    print_message "gocryptfs filesystem initialized successfully."
    # Extract master key from output
    MASTER_KEY=$(print_message "$GOC_INIT_OUTPUT" | grep -oP 'Your master key is:\s*\K.*')
    if [[ -n "$MASTER_KEY" ]]; then
        KEYFILE="/opt/gocryptfs-master-key-$USER_TO_CONVERT.txt"
        print_message "Master Key for $USER_TO_CONVERT (DO NOT SHARE): $MASTER_KEY" > "$KEYFILE"
        chmod 600 "$KEYFILE"
        print_message "Saved gocryptfs master key to $KEYFILE (permissions set to 600)."
    else
        print_message "Warning: Master key not found in output. It may not have been captured. Ensure to note it manually from above output!" >&2
    fi
fi

# 3. Ensure FUSE allow_other is enabled (uncomment user_allow_other in /etc/fuse.conf)
if grep -qs "^#\s*user_allow_other" /etc/fuse.conf; then
    sed -i "s/^#\s*user_allow_other/user_allow_other/" /etc/fuse.conf
    print_message "Enabled 'user_allow_other' in /etc/fuse.conf"
fi

# 4. Create a temporary plain-text mount directory
if [[ ! -d "$PLAIN_DIR" ]]; then
    mkdir -p "$PLAIN_DIR"
    # Own it by the user (so they can access it if we mount as that user)
    chown "$USER_TO_CONVERT":"$USER_TO_CONVERT" "$PLAIN_DIR"
    chmod 700 "$PLAIN_DIR"
    print_message "Created mount point $PLAIN_DIR (owner $USER_TO_CONVERT, mode 700)."
fi

# 5. Mount the encrypted directory to the plain mount point
print_message "Mounting the encrypted filesystem at $PLAIN_DIR to copy data..."
# We attempt to mount as root with allow_other (so we add -allow_other if possible)
# Alternatively, we can run as the user with su, but we'll mount as root for automation.
MOUNT_OPTS="-allow_other"
# Only add -allow_other if fuse.conf has user_allow_other enabled
grep -q "user_allow_other" /etc/fuse.conf || MOUNT_OPTS=""
# Mount (this will prompt for the passphrase)
if gocryptfs $MOUNT_OPTS "$CIPHER_DIR" "$PLAIN_DIR"; then
    print_message "gocryptfs mounted at $PLAIN_DIR"
else
    print_message "Error: Failed to mount $CIPHER_DIR at $PLAIN_DIR. Did you enter the correct password?" >&2
    # Cleanup and abort if mount failed
    fusermount -u "$PLAIN_DIR" 2>/dev/null
    exit 1
fi

# 6. Rsync the user’s current home into the mounted plain directory
print_message "Syncing data from $USER_HOME to $PLAIN_DIR (this may take a while)..."
# Use rsync with archive, ACL, xattrs; exclude the cipher and plain directories themselves if under home (not applicable here as ours are in /home/.cipher- and .plain-).
rsync -aAX --info=progress2 "$USER_HOME/" "$PLAIN_DIR/"
RSYNC_STATUS=$?
if [[ $RSYNC_STATUS -ne 0 ]]; then
    print_message "Warning: rsync completed with errors. Please check the output above for details." >&2
else
    print_message "Home data sync to encrypted store completed."
fi

# (Optional) Place a marker in the plain mount to indicate encryption is active
# This file will be visible only when the encrypted FS is mounted, to reassure the user.
touch "$PLAIN_DIR/ENCRYPTED_HOME_MOUNTED"
# Place a marker in the empty real home to warn if not mounted (will be overwritten by mount when active)
umask 077
print_message "If you see this file, your encrypted home did NOT mount correctly!" > "$USER_HOME/ENCRYPTION_NOT_MOUNTED_WARNING"

# 7. Unmount the plain view
print_message "Unmounting $PLAIN_DIR..."
fusermount -u "$PLAIN_DIR"
sleep 1  # brief pause to ensure unmount completes
# Remove the temporary plain directory (not strictly necessary to remove; do so for cleanliness if unmounted successfully)
if mountpoint -q "$PLAIN_DIR"; then
    print_message "Warning: $PLAIN_DIR is still mounted or busy. Not removing it." >&2
else
    rmdir "$PLAIN_DIR" && print_message "Removed temporary mount point $PLAIN_DIR."
fi

# 8. Move the user's original home aside and create a new empty home directory
BACKUP_DIR="/home/${USER_TO_CONVERT}.unencrypted"
if [[ -d "$USER_HOME" ]]; then
    print_message "Moving original home $USER_HOME to $BACKUP_DIR ..."
    mv "$USER_HOME" "$BACKUP_DIR" || { print_message "Error: Failed to move $USER_HOME to $BACKUP_DIR"; exit 1; }
    # For security, restrict access to the backup
    chown -R root:root "$BACKUP_DIR"
    chmod -R go-rwx "$BACKUP_DIR"
    print_message "Original home moved to $BACKUP_DIR (permissions locked to root)."
fi
# Create a fresh home directory for the user (to serve as mount point)
if [[ ! -d "$USER_HOME" ]]; then
    mkdir "$USER_HOME"
fi
# Set ownership and permissions similar to the backup (assuming backup had correct perms)
# Typically, home directories are user:group (where group might be user's primary group) and 700 perm.
USER_PRIMARY_GROUP=$(id -gn "$USER_TO_CONVERT")
chown "$USER_TO_CONVERT":"$USER_PRIMARY_GROUP" "$USER_HOME"
chmod 700 "$USER_HOME"
print_message "Created new empty home directory $USER_HOME (owner $USER_TO_CONVERT, mode 700)."

# 9. Configure pam_mount to auto-mount the encrypted home at login
PAM_CONF="/etc/security/pam_mount.conf.xml"
# Backup the pam_mount.conf.xml before editing
if [[ -f "$PAM_CONF" ]]; then
    cp -n "$PAM_CONF" "${PAM_CONF}.bak"
fi
# Define the volume XML entry to add
# Using %(USER) macro to generalize for the specified user (pam_mount will substitute the username)
VOLUME_ENTRY="    <volume user=\"$USER_TO_CONVERT\" fstype=\"fuse\" options=\"nodev,nosuid,quiet,nonempty,allow_other\" \\
    path=\"/usr/bin/gocryptfs#${CIPHER_DIR}\" mountpoint=\"${USER_HOME}\" />"
# Check if an entry already exists for this user
if grep -q "path=\"/usr/bin/gocryptfs#${CIPHER_DIR}\"" "$PAM_CONF"; then
    print_message "pam_mount configuration already contains an entry for $USER_TO_CONVERT. Skipping add."
else
    print_message "Adding pam_mount <volume> entry for $USER_TO_CONVERT in $PAM_CONF..."
    # Insert the volume entry above the closing </pam_mount>
    sed -i "\|</pam_mount>| i\\$VOLUME_ENTRY" "$PAM_CONF"
    print_message "Added pam_mount entry: $VOLUME_ENTRY"
fi

# 10. Ensure PAM system-login includes pam_mount
PAM_LOGIN="/etc/pam.d/system-login"
if [[ -f "$PAM_LOGIN" ]]; then
    # Backup system-login
    cp -n "$PAM_LOGIN" "${PAM_LOGIN}.bak"
    # Insert auth and password lines if not present
    if ! grep -q "^auth\s\+optional\s\+pam_mount.so" "$PAM_LOGIN"; then
        sed -i "/^auth\s\+include\s\+system-auth/i auth\toptional\tpam_mount.so" "$PAM_LOGIN"
        print_message "Inserted 'auth optional pam_mount.so' into $PAM_LOGIN"
    fi
    if ! grep -q "^password\s\+optional\s\+pam_mount.so" "$PAM_LOGIN"; then
        sed -i "/^password\s\+include\s\+system-auth/i password\toptional\tpam_mount.so" "$PAM_LOGIN"
        print_message "Inserted 'password optional pam_mount.so' into $PAM_LOGIN"
    fi
    # Insert session lines if not present
    if ! grep -q "pam_mount.so" "$PAM_LOGIN"; then
        # If no pam_mount at all in session, add the recommended lines
        sed -i "/^session\s\+include\s\+system-auth/i session\t[success=1 default=ignore]\tpam_succeed_if.so service=systemd-user quiet" "$PAM_LOGIN"
        sed -i "/^session\s\+include\s\+system-auth/i session\toptional\tpam_mount.so" "$PAM_LOGIN"
        print_message "Inserted 'session optional pam_mount.so' and pam_succeed_if rule into $PAM_LOGIN"
    else
        if ! grep -q "^session\s\+optional\s\+pam_mount.so" "$PAM_LOGIN"; then
            sed -i "/^session\s\+include\s\+system-auth/i session\toptional\tpam_mount.so" "$PAM_LOGIN"
            print_message "Inserted 'session optional pam_mount.so' into $PAM_LOGIN"
        fi
        # Optionally ensure pam_succeed_if is present to avoid double-mount issues
        if ! grep -q "pam_succeed_if.so service=systemd-user" "$PAM_LOGIN"; then
            sed -i "/session\s\+optional\s\+pam_mount.so/i session\t[success=1 default=ignore]\tpam_succeed_if.so service=systemd-user quiet" "$PAM_LOGIN"
            print_message "Inserted pam_succeed_if rule into $PAM_LOGIN"
        fi
    fi
else
    print_message "Error: $PAM_LOGIN not found. PAM configuration might be different than expected." >&2
fi

# 11. Final ownership/permission checks
# Ensure the cipher directory is owned by user (some files might be root-owned if created by root)
chown -R "$USER_TO_CONVERT":"$USER_PRIMARY_GROUP" "$CIPHER_DIR"
print_message "Verified ownership of $CIPHER_DIR and its contents belong to $USER_TO_CONVERT."
# Ensure the new home mount point has correct owner (should already, but just in case)
chown "$USER_TO_CONVERT":"$USER_PRIMARY_GROUP" "$USER_HOME"
chmod 700 "$USER_HOME"
# Remind about backup directory
print_message "Encryption setup for $USER_TO_CONVERT is complete. Original unencrypted home is at $BACKUP_DIR."

print_message ""
print_message ">> All steps completed. Please log out and log back in as $USER_TO_CONVERT to test the encrypted home mount."
print_message ">> After confirming everything works, you may securely delete $BACKUP_DIR to remove the unencrypted copy of the data."
