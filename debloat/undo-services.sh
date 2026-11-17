#!/bin/sh
# Re-enable everything disable-services.sh may have turned off.
# Run:  sudo sh debloat/undo-services.sh
[ "$(id -u)" = 0 ] || { echo "run with: sudo sh $0"; exit 1; }
for s in avahi-daemon saned nfs-kernel-server nfs-common rpcbind smbd nmbd \
  open-vm-tools spice-vdagent openvpn smartmontools rsync speech-dispatcher \
  unattended-upgrades acpi-fakekey uuidd bootlogs tlp cups cups-browsed bluetooth; do
  [ -x "/etc/init.d/$s" ] && update-rc.d "$s" enable >/dev/null 2>&1 && echo "  on: $s"
done
echo "vm.swappiness = 15" > /etc/sysctl.d/99-swappiness_mx.conf
echo "Done. Reboot to apply."
