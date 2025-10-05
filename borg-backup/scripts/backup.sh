#!/bin/bash

# Borg Backup Script
# Backs up /etc directory to remote repository with retention policy

set -e

# Configuration
export BORG_PASSPHRASE='Otus1234'
REPO="borg@192.168.100.160:/var/backup/"
BACKUP_TARGET="/etc"
BACKUP_NAME="etc-$(date +%Y-%m-%d_%H:%M:%S)"
LOG_FILE="/var/log/borg-backup.log"
LOCK_FILE="/var/run/borg-backup.lock"
SSH_KEY="/home/vagrant/.ssh/borg_key"

# Set SSH options for Borg
export BORG_RSH="ssh -i $SSH_KEY -o StrictHostKeyChecking=no"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    logger -t "borg-backup" "$1"
}

# Error handling
handle_error() {
    log "ERROR: $1"
    exit 1
}

# Check if backup is already running
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        log "Backup is already running (lock file exists: $LOCK_FILE)"
        exit 0
    fi
    echo $$ > "$LOCK_FILE"
}

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE"
}

# Set trap for cleanup
trap cleanup EXIT

# Main backup function
create_backup() {
    log "Starting backup process"
    
    # Create backup with compression and exclusion of cache files
    log "Creating backup: $BACKUP_NAME"
    
    borg create \
        --verbose \
        --filter AME \
        --list \
        --stats \
        --show-rc \
        --compression lz4 \
        --exclude-caches \
        --exclude '/etc/.cache' \
        --exclude '/etc/*.tmp' \
        --exclude '/etc/*.swp' \
        --exclude '/etc/*.lock' \
        "$REPO"::"$BACKUP_NAME" \
        "$BACKUP_TARGET" 2>&1 | tee -a "$LOG_FILE"
    
    local create_exit=${PIPESTATUS[0]}
    
    if [ $create_exit -eq 0 ]; then
        log "Backup created successfully: $BACKUP_NAME"
    elif [ $create_exit -eq 1 ]; then
        log "Backup finished with warnings: $BACKUP_NAME"
    else
        handle_error "Backup creation failed with exit code: $create_exit"
    fi
}

# Prune old backups according to retention policy
prune_backups() {
    log "Pruning old backups with retention policy"
    
    # Retention policy:
    # - Keep daily backups for 90 days (last 3 months)
    # - Keep weekly backups for 8 weeks
    # - Keep monthly backups for 12 months
    # - Keep yearly backups for 1 year
    borg prune \
        --list \
        --prefix 'etc-' \
        --show-rc \
        --keep-daily 90 \
        --keep-weekly 8 \
        --keep-monthly 12 \
        --keep-yearly 1 \
        "$REPO" 2>&1 | tee -a "$LOG_FILE"
    
    local prune_exit=${PIPESTATUS[0]}
    
    if [ $prune_exit -eq 0 ]; then
        log "Backup pruning completed successfully"
    elif [ $prune_exit -eq 1 ]; then
        log "Backup pruning finished with warnings"
    else
        handle_error "Backup pruning failed with exit code: $prune_exit"
    fi
}

# Check repository integrity (run occasionally to save resources)
check_repository() {
    local current_hour=$(date +%H)
    
    # Run full check only once per day at 2 AM
    if [ "$current_hour" = "02" ]; then
        log "Performing full repository integrity check"
        
        borg check \
            --verbose \
            --show-rc \
            "$REPO" 2>&1 | tee -a "$LOG_FILE"
        
        local check_exit=${PIPESTATUS[0]}
        
        if [ $check_exit -eq 0 ]; then
            log "Repository check completed successfully"
        elif [ $check_exit -eq 1 ]; then
            log "Repository check finished with warnings"
        else
            handle_error "Repository check failed with exit code: $check_exit"
        fi
    else
        log "Skipping full repository check (runs only at 2 AM)"
        
        # Quick repository info
        borg info "$REPO" | grep -E "(Repository size|All archives)" | while read -r line; do
            log "  $line"
        done
    fi
}

# List existing backups for logging
list_backups() {
    log "Current backups in repository:"
    borg list --short "$REPO" 2>&1 | while read -r line; do
        log "  $line"
    done
}

# Display backup statistics
show_statistics() {
    log "Backup repository statistics:"
    borg info "$REPO" | grep -E "(All archives|This archive|Repository size)" | while read -r line; do
        log "  $line"
    done
}

# Main execution
main() {
    log "=== Starting Borg Backup ==="
    
    # Check for lock file
    check_lock
    
    # Create backup
    create_backup
    
    # Prune old backups
    prune_backups
    
    # Check repository
    check_repository
    
    # List current backups
    list_backups
    
    # Show statistics
    show_statistics
    
    log "=== Borg Backup Completed Successfully ==="
}

# Run main function
main
