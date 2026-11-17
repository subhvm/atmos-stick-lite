#!/bin/sh
# Step 1 of the ACPI fix: check kernel support, install tools, dump and decompile firmware tables.
# Run:  sudo sh acpi/dump-tables.sh
# Output goes to ~/acpi-fix (never commit these files: they are your vendor's firmware).
set -e
[ "$(id -u)" = 0 ] || { echo "run with: sudo sh $0"; exit 1; }
grep -q '^CONFIG_ACPI_TABLE_UPGRADE=y' "/boot/config-$(uname -r)" \
  || { echo "Kernel lacks CONFIG_ACPI_TABLE_UPGRADE=y: this method won't work."; exit 1; }

apt-get install -y acpica-tools cpio
U=${SUDO_USER:?run via sudo from your normal user}
D=$(getent passwd "$U" | cut -d: -f6)/acpi-fix
mkdir -p "$D" && cd "$D"
acpidump -b
if ls ssdt*.dat >/dev/null 2>&1; then iasl -e ssdt*.dat -d dsdt.dat; else iasl -d dsdt.dat; fi
cp dsdt.dsl dsdt.dsl.orig
chown -R "$U:$U" "$D"

echo; echo "== Pin controllers:"
for d in /sys/bus/acpi/devices/INT33FF:*; do
  echo "  $(basename "$d")  path=$(cat "$d/path")  status=$(cat "$d/status" 2>/dev/null)"
done
echo; echo "Now edit $D/dsdt.dsl (see docs/acpi-cherryview-fix.md), then run: sh acpi/build-override.sh"
