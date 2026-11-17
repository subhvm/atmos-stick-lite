#!/bin/sh
# Turn off unneeded background services on MX Linux (sysvinit: systemctl does nothing here).
# Run:   sudo sh debloat/disable-services.sh
# Undo:  sudo sh debloat/undo-services.sh
# Edit SERVICES to keep what you use. Missing services are skipped.
set -u
[ "$(id -u)" = 0 ] || { echo "run with: sudo sh $0"; exit 1; }

SERVICES="avahi-daemon saned nfs-kernel-server nfs-common rpcbind smbd nmbd
open-vm-tools spice-vdagent openvpn smartmontools rsync speech-dispatcher
unattended-upgrades acpi-fakekey uuidd bootlogs"
# tlp: power saving is pointless with no battery, and it suspends USB card readers.
SERVICES="$SERVICES tlp"
# Uncomment if you don't print or use Bluetooth:
# SERVICES="$SERVICES cups cups-browsed bluetooth"

for s in $SERVICES; do
  [ -x "/etc/init.d/$s" ] || continue
  service "$s" stop >/dev/null 2>&1
  update-rc.d "$s" disable >/dev/null 2>&1 && echo "  off: $s" || echo "  skip: $s"
done

# MX uses zram (compressed RAM) for swap, so let the kernel use it readily.
# This keeps more of the 2 GB free and avoids swapping to the eMMC.
echo "vm.swappiness = 100" > /etc/sysctl.d/99-swappiness_mx.conf
sysctl -q vm.swappiness=100
echo "Done. Reboot when convenient."
