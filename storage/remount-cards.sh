#!/bin/bash
# Re-attach the cards after a reader disconnect: drop stale mounts, check, mount again.
# Run:  sudo bash storage/remount-cards.sh
[ "$(id -u)" = 0 ] || { echo "Run with sudo"; exit 1; }
. "$(dirname "$0")/config.sh"
for mp in "$MAIN" "$SPARE"; do
  echo "== $mp"
  uuid=$(awk -v m="$mp" '$2==m {sub("UUID=","",$1); print $1}' /etc/fstab)
  dev=$(blkid -U "$uuid" 2>/dev/null)
  if mountpoint -q "$mp" && ! card_ok "$mp"; then umount -l "$mp" && echo "   removed stale mount"; fi
  [ -n "$dev" ] || { echo "   card not detected: check the reader"; continue; }
  if mountpoint -q "$mp"; then echo "   already OK"; continue; fi
  fsck.exfat -y "$dev" | tail -1
  mount "$mp" && echo "   mounted ($dev)"
done
df -h "$MAIN" "$SPARE"
