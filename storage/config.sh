# Storage settings shared by the storage/ scripts. EDIT BEFORE RUNNING ANYTHING.
#
# Find your cards' stable names with:
#   ls -l /dev/disk/by-id/ | grep -v part
#   lsblk -o NAME,SIZE,MODEL,TRAN
# and their exact size in 512-byte sectors with:
#   cat /sys/block/sdX/size        (or mmcblkN for a built-in SD slot)
#
# The size check is a safety lock: the format script refuses to touch a device
# whose size doesn't match, so it can never wipe your system drive by mistake.

CARD1_ID="/dev/disk/by-id/usb-Generic_MassStorageClass_XXXXXXXXXXXX-0:0"
CARD1_SECTORS=245452800    # 128 GB card
CARD2_ID="/dev/disk/by-id/usb-Generic_MassStorageClass_XXXXXXXXXXXX-0:1"
CARD2_SECTORS=500695040    # 256 GB card

MAIN=/srv/cloud1           # where you keep files
SPARE=/srv/cloud2          # holds the nightly backup of MAIN, plus spare space
OWNER_UID=1000             # your user's uid (run: id -u)
OWNER_GID=1000

# USB vendor:product IDs of the card reader (and the hub it sits on) that must
# never be autosuspended. Find them with: lsusb
READER_USB_IDS="05e3:0764"
