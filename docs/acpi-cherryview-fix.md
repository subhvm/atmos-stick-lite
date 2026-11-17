# Fix: `cherryview-pinctrl INT33FF:04 … error -61`

```
cherryview-pinctrl INT33FF:04: probe with driver cherryview-pinctrl failed with error -61
```

**What it means:** the firmware's ACPI tables describe a fifth GPIO pin-controller group (`INT33FF:04`) that this SoC variant doesn't actually have. The driver gets no data (`-61` = `ENODATA`) and skips it. It's **harmless** and does **not** cause boot hangs (see [boot-hang-fix.md](boot-hang-fix.md)). This fix just makes the firmware stop advertising the device.

**How:** patch the DSDT so the device's `_STA` ("am I present?") returns 0, then load the patched table at every boot through an early initrd. There's no kernel rebuild, and it's fully reversible.

Tested on Intel Compute Stick STK1AW32SC, kernel 6.12 (Debian 13 / MX 25). Your device names and IDs may differ, so always use what your own machine prints.

## 1. Dump the tables

```sh
sudo sh acpi/dump-tables.sh
```

This checks for `CONFIG_ACPI_TABLE_UPGRADE=y`, dumps the tables to `~/acpi-fix`, decompiles the DSDT, and lists the pin controllers. Note the path of `INT33FF:04`. On the STK1AW32SC it is `\_SB_.GPO4`.

## 2. Edit `~/acpi-fix/dsdt.dsl`

**a) Make the device report "not present".** Find `Device (GPO4)` (your name from step 1) and its `_STA`. On the STK1AW32SC it was:

```diff
             Method (_STA, 0, NotSerialized)  // _STA: Status
             {
-                If ((SOCS <= 0x04))
-                {
-                    Return (Zero)
-                }
-                Else
-                {
-                    Return (0x0F)
-                }
+                Return (Zero)
             }
```

If there's `Name (_STA, 0x0F)` instead, change it to `Name (_STA, Zero)`. If there's no `_STA` at all, add `Method (_STA, 0, NotSerialized) { Return (Zero) }` under `_UID`.

**b) Bump the table revision** (the last number on the `DefinitionBlock` line) by one, so the kernel accepts the override:

```diff
-DefinitionBlock ("", "DSDT", 2, "Intel ", "COMSTKFC", 0x01072009)
+DefinitionBlock ("", "DSDT", 2, "Intel ", "COMSTKFC", 0x0107200A)
```

Don't touch the quoted OEM IDs. They must match the original exactly.

## 3. Build and install

```sh
sh acpi/build-override.sh      # shows your diff, compiles, packs ~/acpi-fix/acpi_override
```

Then run the four install commands it prints. They copy the file to `/boot`, add `GRUB_EARLY_INITRD_LINUX_CUSTOM="acpi_override"`, run `update-grub` and reboot.

If `iasl` reports errors, they are often decompiler quirks in the original table, unrelated to your edit. Fix those lines and compile again.

## 4. Verify

```sh
sudo dmesg | grep -iE 'table upgrade|cherryview|AE_'
```

- You should see `ACPI: Table Upgrade: override [DSDT-…]`.
- The `error -61` line should be gone.
- `wc -c < /sys/firmware/acpi/tables/DSDT` should equal the size of `~/acpi-fix/dsdt.aml`.

It survives kernel updates, because GRUB adds the override to every kernel entry. After a kernel update, re-run the `dmesg` check above.

## Undo

- **One boot:** at GRUB press `e`, delete `/boot/acpi_override` from the `initrd` line, then press Ctrl+X.
- **Permanently:** remove the `GRUB_EARLY_INITRD_LINUX_CUSTOM` line, run `sudo update-grub && sudo rm /boot/acpi_override`.

> Don't publish your `.dat`/`.dsl`/`.aml` files. They're your vendor's firmware, and some tables (such as MSDM) contain your Windows product key. The repo's `.gitignore` blocks them.
