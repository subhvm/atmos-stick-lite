# Fix: boot gets stuck after the MX logo (Cherry Trail)

## Symptom

The MX logo shows, an error line appears, and the screen freezes. The last line on screen is usually:

```
cherryview-pinctrl INT33FF:04: probe with driver cherryview-pinctrl failed with error -61
```

**That line is a red herring.** It's printed on every boot, including good ones. It's just the last text left on screen. (To get rid of it anyway, see [acpi-cherryview-fix.md](acpi-cherryview-fix.md).)

## How it was diagnosed

| Tried | Result |
|---|---|
| `kern.log` | Freezing boots end mid-line, padded with NUL bytes: the log was cut off, not a clean crash. |
| Hardware clock in local time | Caused fsck "last mount time is in the future" warnings. Fixed with `sudo hwclock --systohc --utc`, but not the cause of the hang. |
| `intel_idle.max_cstate=1` | Still hung. |
| `i915.enable_dc=0 i915.enable_psr=0 i915.enable_fbc=0` | Still hung. |
| `Xorg.0.log.old` from a hung boot | Stops right as X loads the modesetting driver: the first display modeset. |
| **Ctrl+Alt+F2 at the stuck screen** | **Boot continues normally.** The machine wasn't frozen. |

So the system was stuck at the display handoff from the **Plymouth** boot splash to X/LightDM.

## Fix

MX puts `splash` in **both** GRUB command-line variables. Remove it from both:

```sh
sudo sed -i -E '/^GRUB_CMDLINE_LINUX(_DEFAULT)?=/ s/ ?\bsplash\b//' /etc/default/grub
grep ^GRUB_CMDLINE /etc/default/grub     # check: no "splash" left
sudo update-grub
sudo reboot
```

Optionally also purge Plymouth (`debloat/remove-packages.sh` does this): `sudo apt purge plymouth plymouth-themes-mx`.

Reboot 3–4 times to be sure, since the hang was intermittent.

## Also worth doing on these sticks

```sh
sudo hwclock --systohc --utc        # store the RTC in UTC; stops bogus fsck warnings
```

If some log lines show dates like 2015-01-01, the RTC lost power at some point, which can mean a weak CMOS battery.
