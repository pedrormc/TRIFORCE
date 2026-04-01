#!/data/data/com.termux/files/usr/bin/bash
# TRIFORCE — Backup and restore ~/.claude/ (Mobile)
# Usage:
#   backup-mobile.sh backup    — backup ~/.claude/ to ~/storage/downloads/
#   backup-mobile.sh restore   — restore from ~/storage/downloads/
#   backup-mobile.sh cron      — setup daily cron backup

BACKUP_DIR="$HOME/storage/downloads/claude-backup"
CLAUDE_DIR="$HOME/.claude"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/claude-backup-$TIMESTAMP.tar.gz"

case "$1" in
    backup)
        mkdir -p "$BACKUP_DIR"
        echo "Backing up $CLAUDE_DIR..."
        tar czf "$BACKUP_FILE" \
            --exclude='*.log' \
            --exclude='node_modules' \
            --exclude='.cache' \
            -C "$HOME" .claude/
        echo "Backup saved to: $BACKUP_FILE"
        echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"

        # Keep only last 5 backups
        ls -t "$BACKUP_DIR"/claude-backup-*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
        echo "Old backups cleaned (keeping last 5)"
        ;;

    restore)
        LATEST=$(ls -t "$BACKUP_DIR"/claude-backup-*.tar.gz 2>/dev/null | head -1)
        if [ -z "$LATEST" ]; then
            echo "No backup found in $BACKUP_DIR"
            exit 1
        fi
        echo "Restoring from: $LATEST"
        echo "WARNING: This will overwrite current ~/.claude/"
        read -p "Continue? [y/N] " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            tar xzf "$LATEST" -C "$HOME"
            echo "Restored successfully!"
            echo "Run 'claude plugins list' to verify."
        else
            echo "Cancelled."
        fi
        ;;

    cron)
        # Setup daily backup via crond
        mkdir -p "$HOME/.config/crontabs"
        CRON_LINE="0 3 * * * $HOME/backup-mobile.sh backup >> $HOME/logs/backup.log 2>&1"
        echo "$CRON_LINE" > "$HOME/.config/crontabs/claude-backup"

        if command -v crond &> /dev/null; then
            sv-enable crond 2>/dev/null || true
            echo "Cron backup configured: daily at 3:00 AM"
        else
            echo "crond not available. Install: pkg install termux-services"
            echo "Then: sv-enable crond && backup-mobile.sh cron"
        fi
        ;;

    *)
        echo "TRIFORCE — Claude Code Backup (Mobile)"
        echo ""
        echo "Usage:"
        echo "  backup-mobile.sh backup   — Create backup"
        echo "  backup-mobile.sh restore  — Restore latest backup"
        echo "  backup-mobile.sh cron     — Setup daily cron backup"
        ;;
esac
