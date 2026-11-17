#!/bin/sh
# Hide login apps you don't need on a 2 GB machine (per-user, no sudo).
# Works by writing ~/.config/autostart/<name>.desktop with Hidden=true,
# which overrides the system copy in /etc/xdg/autostart.
#   bash debloat/trim-autostart.sh          # apply
#   bash debloat/trim-autostart.sh --undo   # restore
# Edit the list below and remove anything you want to keep.
APPS="zpicom conky magnus-autostart onboard-autostart orca-autostart at-spi-dbus-bus
xfce4-notes-autostart spice-vdagent print-applet blueman Blueman-start
zstartup-sound mx-tweak-tray-app-autostart cleanup-notifier-mx mx-updater-autostart
mx-usb-unmounter gnome-keyring-pkcs11 gnome-keyring-ssh xfce4-screensaver
xfce4-clipman-plugin-autostart zrestore-software-brightness"

DIR="$HOME/.config/autostart"
BAK="$HOME/.config/autostart-backup"
mkdir -p "$DIR"

if [ "${1:-}" = --undo ]; then
  for a in $APPS; do rm -f "$DIR/$a.desktop"; done
  [ -d "$BAK" ] && cp "$BAK"/*.desktop "$DIR"/ 2>/dev/null
  echo "Restored. Log out and back in."; exit 0
fi

mkdir -p "$BAK"
for a in $APPS; do
  [ -f "$DIR/$a.desktop" ] && [ ! -f "$BAK/$a.desktop" ] && cp "$DIR/$a.desktop" "$BAK/"
  [ -f "/etc/xdg/autostart/$a.desktop" ] || [ -f "$DIR/$a.desktop" ] || continue
  printf '[Desktop Entry]\nType=Application\nName=%s\nHidden=true\n' "$a" > "$DIR/$a.desktop"
  echo "  hidden: $a"
  pkill -f "$a" 2>/dev/null || true
done
echo "Done. Takes full effect at next login."
