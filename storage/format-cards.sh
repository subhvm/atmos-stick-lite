#!/bin/bash
# ERASES both cards in storage/config.sh and formats them as exFAT (works on Windows + macOS),
# then adds them to /etc/fstab so they mount at boot. "nofail" means the PC still boots if a card is missing.
# Run:  sudo bash storage/format-cards.sh
set -eu
[ "$(id -u)" = 0 ] || { echo "Run with sudo"; exit 1; }
. "$(dirname "$0")/config.sh"
command -v mkfs.exfat >/dev/null || apt-get install -y exfatprogs

declare -A CARDS=( [cloud1]="$CARD1_ID $CARD1_SECTORS $MAIN" [cloud2]="$CARD2_ID $CARD2_SECTORS $SPARE" )

for name in cloud1 cloud2; do
  read -r link sectors mp <<<"${CARDS[$name]}"
  dev=$(readlink -f "$link") || { echo "$name: $link not found"; exit 1; }
  [ -b "$dev" ] || { echo "$name: $link not found"; exit 1; }
  [ "$(cat /sys/block/"${dev#/dev/}"/size)" = "$sectors" ] || { echo "$name: $dev has an unexpected size, aborting"; exit 1; }
  findmnt -rno TARGET -S "$dev" | grep -qx / && { echo "$name: $dev is the system drive!"; exit 1; }
  echo "  $name -> $dev ($(( sectors / 2097152 )) GiB) -> $mp"
done
echo; echo "ALL DATA on both devices above will be permanently erased."
read -rp "Type WIPE to continue: " ans
[ "$ans" = WIPE ] || { echo "Cancelled."; exit 1; }

for name in cloud1 cloud2; do
  read -r link sectors mp <<<"${CARDS[$name]}"
  dev=$(readlink -f "$link")
  echo "== $name ($dev)"
  for p in $(lsblk -lnpo NAME "$dev" | tail -n +2) "$dev"; do umount "$p" 2>/dev/null || true; done
  wipefs -a "$dev" >/dev/null
  # MBR + partition type 0x07 is the most compatible layout for Windows and macOS
  printf 'label: dos\ntype=7\n' | sfdisk -q "$dev"
  sleep 2; partprobe "$dev" 2>/dev/null || true; sleep 1
  part=$(lsblk -lnpo NAME "$dev" | sed -n 2p)
  mkfs.exfat -q -L "$name" "$part"
  uuid=$(blkid -s UUID -o value "$part")
  mkdir -p "$mp"
  sed -i "\#[[:space:]]$mp[[:space:]]#d" /etc/fstab
  # last field 2 = check (fsck) the card at every boot
  echo "UUID=$uuid $mp exfat noatime,nofail,uid=$OWNER_UID,gid=$OWNER_GID,umask=022 0 2" >> /etc/fstab
  mount "$mp"
  echo "   mounted at $mp"
done
df -h "$MAIN" "$SPARE"
echo "Done."
