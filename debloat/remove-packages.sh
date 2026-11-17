#!/bin/sh
# Remove apps and packages a lightweight home server doesn't need.
# Run:  sudo sh debloat/remove-packages.sh
# READ THE LIST FIRST and delete anything you use. A dry run is shown before anything is removed.
set -euf   # -f: no filename globbing, so libreoffice* reaches apt as-is
[ "$(id -u)" = 0 ] || { echo "run with: sudo sh $0"; exit 1; }

echo "Waiting for any running apt/dpkg to finish..."
while pgrep -x dpkg >/dev/null || pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null; do sleep 10; done

# Keep everything the mx-apps metapackage pulls in from being auto-removed later.
apt-mark manual $(apt-cache depends --installed mx-apps 2>/dev/null | awk '/Depends|Recommends/{print $2}' | grep -v '^<') >/dev/null 2>&1 || true

PKGS="
thunderbird strawberry luckybackup conky-all hardinfo2 xfce4-notes xfce4-notes-plugin
xfburn asunder falkon mx-iso-template
libreoffice* lo-main-helper default-jre default-jre-headless openjdk-21-jre*
orca onboard magnus speech-dispatcher
flatpak modemmanager open-vm-tools spice-vdagent virtualbox-guest-utils openvpn
nfs-kernel-server smartmontools tumbler tumbler-plugins-extra tumbler-common
plymouth plymouth-themes-mx
rtl8821cu-dkms rtl8812au-dkms broadcom-sta-dkms
"
# Not removed by default (uncomment if you don't need them):
# PKGS="$PKGS cups cups-browsed printer-driver-all hplip system-config-printer"   # printing
# PKGS="$PKGS bluez blueman"                                                      # Bluetooth
# PKGS="$PKGS samba avahi-daemon"                                                 # Windows sharing / .local names
# NOTE: only remove the *-dkms Wi-Fi drivers your hardware doesn't use (check: lspci -k; lsusb).

INST=""
for p in $PKGS; do
  case "$p" in *\**) INST="$INST $p" ;; *) dpkg -s "$p" >/dev/null 2>&1 && INST="$INST $p" ;; esac
done
[ -n "$INST" ] || { echo "Nothing to remove."; exit 0; }

echo "== Dry run"
apt-get -s purge $INST | grep '^Purg' || true
printf "Proceed with removal? [y/N] "; read ans
[ "$ans" = y ] || [ "$ans" = Y ] || { echo "Cancelled."; exit 1; }

apt-get purge -y $INST || true
apt-get autoremove --purge -y
apt-get clean
echo "Done. Reboot when convenient."
