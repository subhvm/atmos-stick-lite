# Two SD cards as home cloud storage

A Compute Stick has a tiny 32 GB eMMC, so the storage lives on two SD cards: one in the built-in slot, one in a USB card reader.

```
/srv/cloud1   main storage: put your files here      (128 GB)
/srv/cloud2   nightly backup of cloud1 + spare space   (256 GB)
```

## Design choices

| Choice | Why |
|---|---|
| **exFAT**, not ext4 | Pull a card and plug it into Windows or macOS, and it just works. The trade-off is no Unix permissions, so ownership is set at mount time (`uid=`/`gid=`). |
| **Mount at boot** via `/etc/fstab` with `nofail` | Available before anyone logs in (good for a server). The box still boots if a card is missing. |
| **fsck at every boot** (`… 0 2`) | Catches corruption from power cuts early. |
| **Mirror + 30-day history** (rsync `--backup-dir`) | One card can die, and an accidental delete can be undone for a month. Not RAID, which would be overkill on SD cards. |
| **Tailscale** for remote access | Encrypted, no port forwarding, nothing exposed to the public internet. |

## Steps

1. **Edit `storage/config.sh`**: card IDs, sizes, your uid, reader USB IDs. The instructions are in the file.
2. **Format** (erases both cards):
   ```sh
   sudo bash storage/format-cards.sh
   ```
3. **If the cards keep disappearing** (very likely with a USB reader on these sticks):
   ```sh
   sudo bash storage/fix-card-reader.sh
   ```
   Cause: TLP autosuspends USB devices after 2 s idle, so the reader drops off and comes back under a new device name, and the old mounts go stale. Better still, put one card in the stick's **built-in SD slot**, which doesn't have this problem.
4. **Nightly backup** at 3 AM, as your user:
   ```sh
   (crontab -l 2>/dev/null; echo "0 3 * * * $PWD/storage/backup.sh >> $HOME/cloud-backup.log 2>&1") | crontab -
   ```
   Note: if `/srv/cloud1` is empty, the backup folder stays empty too. That's expected.
5. **Remote access** (optional):
   ```sh
   sudo bash storage/setup-tailscale.sh
   ```
   Install the Tailscale app on your phone or laptop, sign in to the same account, and the stick is reachable at its `100.x.y.z` address from anywhere.

## After a reader hiccup

```sh
sudo bash storage/remount-cards.sh
```
