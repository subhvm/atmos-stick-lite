#!/bin/bash
# Mirror MAIN -> SPARE/backup. Files you delete or change are kept for 30 days in
# SPARE/backup-old/<date>, so an accidental delete can be undone.
# Install as a nightly job (as your normal user, no sudo):
#   (crontab -l 2>/dev/null; echo "0 3 * * * $PWD/storage/backup.sh >> $HOME/cloud-backup.log 2>&1") | crontab -
. "$(dirname "$0")/config.sh"
DST="$SPARE/backup"; OLD="$SPARE/backup-old"
# Never run with a card missing: an empty mount point would otherwise wipe the backup.
mountpoint -q "$MAIN" && mountpoint -q "$SPARE" || { echo "$(date '+%F %T') SKIPPED: card not mounted"; exit 1; }
mkdir -p "$DST" "$OLD"
# exFAT has no owners/permissions and 2 s timestamps, hence -rt and --modify-window=1
if rsync -rt --modify-window=1 --delete --backup --backup-dir="$OLD/$(date +%F)" "$MAIN/" "$DST/"; then
  echo "$(date '+%F %T') OK: $(du -sh "$DST" | cut -f1) backed up"
else
  echo "$(date '+%F %T') ERROR: rsync failed"
fi
find "$OLD" -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +
