#!/bin/sh
# Step 3 of the ACPI fix: compile your edited dsdt.dsl and package it as an early-initrd override.
# Run as your normal user:  sh acpi/build-override.sh
# Then install with the commands it prints.
set -e
D=${1:-$HOME/acpi-fix}
cd "$D"
[ -f dsdt.dsl.orig ] || { echo "Run acpi/dump-tables.sh first."; exit 1; }
cmp -s dsdt.dsl dsdt.dsl.orig && { echo "dsdt.dsl is unchanged: edit it first."; exit 1; }

echo "== Your changes:"
diff dsdt.dsl.orig dsdt.dsl || true
echo
iasl -tc dsdt.dsl | tail -3
[ -f dsdt.aml ] || { echo "Compile failed."; exit 1; }

rm -rf override acpi_override
mkdir -p override/kernel/firmware/acpi
cp dsdt.aml override/kernel/firmware/acpi/
(cd override && find kernel | cpio -H newc --create --quiet > ../acpi_override)
echo
echo "Built $D/acpi_override. Install it with:"
echo
echo "  sudo cp $D/acpi_override /boot/acpi_override"
echo "  grep -q GRUB_EARLY_INITRD_LINUX_CUSTOM /etc/default/grub || echo 'GRUB_EARLY_INITRD_LINUX_CUSTOM=\"acpi_override\"' | sudo tee -a /etc/default/grub"
echo "  sudo update-grub"
echo "  sudo reboot"
