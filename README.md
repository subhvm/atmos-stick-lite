# atmos-stick-lite

Turn a 2 GB Intel Atom box (tested on an **Intel Compute Stick STK1AW32SC**, Atom x5-Z8330 / Cherry Trail) running **MX Linux 25 (sysvinit)** into a lean, stable little home server with SD-card cloud storage.

Everything here was worked out on real hardware, one problem at a time. Each script is short, commented, asks for confirmation before it touches anything risky, and has an undo path.

| Area | What it does |
|---|---|
| [`debloat/`](debloat) | Trims login apps, background services and packages. Tunes Firefox for 2 GB RAM. |
| [`docs/boot-hang-fix.md`](docs/boot-hang-fix.md) | Fixes the "stuck after the MX logo" boot hang on Cherry Trail. |
| [`acpi/`](acpi) + [`docs/acpi-cherryview-fix.md`](docs/acpi-cherryview-fix.md) | Removes the `cherryview-pinctrl INT33FF:04 … error -61` message by overriding the DSDT. |
| [`storage/`](storage) + [`docs/sd-card-cloud.md`](docs/sd-card-cloud.md) | Two SD cards as exFAT cloud storage, mounted at boot, fixes for USB-reader dropouts, nightly versioned backup, Tailscale remote access. |

## Why sysvinit matters

MX Linux boots with **sysvinit** by default, so `systemctl disable …` silently does nothing. Every script here uses `update-rc.d` / `service` instead.

## Quick start

```sh
git clone https://github.com/subhvm/atmos-stick-lite
cd atmos-stick-lite

# 1. Read the lists at the top of each script and delete anything you still use.
# 2. Then, in a real terminal (sudo needs to prompt for your password):
bash debloat/trim-autostart.sh          # no sudo, per-user
sudo sh debloat/remove-packages.sh
sudo sh debloat/disable-services.sh
sudo sh debloat/firefox-lite.sh         # optional
sudo reboot
```

Storage and the ACPI fix are hardware-specific, so follow their guides in `docs/`.

## Results on the test stick

- Boots cleanly with no splash hang and no ACPI errors in `dmesg`
- 53 packages removed (LibreOffice, Java, Thunderbird, Flatpak, Plymouth, …), about 20 services and login apps off
- zram handles swap, so the eMMC isn't worn by swap writes
- 128 GB + 256 GB of storage that also works plugged into Windows or macOS

## Undo

- `debloat/undo-services.sh` re-enables services.
- `debloat/trim-autostart.sh --undo` restores login apps.
- Removed packages: `sudo apt install <name>`.
- ACPI override: see the "Undo" section of the guide.

## Disclaimer

These scripts change system settings and some of them **erase disks**. Read them before running. They are provided as-is under the MIT license, with no warranty.
# atmos-stick-lite
