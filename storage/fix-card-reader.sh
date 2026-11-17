#!/bin/bash
# Symptom: SD cards in a USB reader vanish every few seconds and come back under a new
# device name, breaking the mounts. Cause: USB autosuspend (TLP's default is 2 s idle).
# Fix: exclude the reader (and its hub) from autosuspend, permanently, then remount.
# Run:  sudo bash storage/fix-card-reader.sh
[ "$(id -u)" = 0 ] || { echo "Run with sudo"; exit 1; }
. "$(dirname "$0")/config.sh"

# 1) TLP: never autosuspend these devices
mkdir -p /etc/tlp.d
echo "USB_DENYLIST=\"$READER_USB_IDS\"" > /etc/tlp.d/50-card-reader.conf

# 2) udev: keep them awake whenever they (re)connect, even without TLP
: > /etc/udev/rules.d/50-card-reader-no-suspend.rules
for id in $READER_USB_IDS; do
  echo "ACTION==\"add|change\", SUBSYSTEM==\"usb\", ATTR{idVendor}==\"${id%:*}\", ATTR{idProduct}==\"${id#*:}\", TEST==\"power/control\", ATTR{power/control}=\"on\"" \
    >> /etc/udev/rules.d/50-card-reader-no-suspend.rules
done
udevadm control --reload-rules

# 3) right now: wake them
for d in /sys/bus/usb/devices/*; do
  id="$(cat "$d/idVendor" 2>/dev/null):$(cat "$d/idProduct" 2>/dev/null)"
  [[ " $READER_USB_IDS " == *" $id "* ]] && echo on > "$d/power/control" && echo "  kept awake: $id"
done
command -v tlp >/dev/null && tlp start >/dev/null 2>&1
echo "Waiting for cards to settle..."; sleep 5
bash "$(dirname "$0")/remount-cards.sh"
