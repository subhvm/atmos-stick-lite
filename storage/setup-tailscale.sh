#!/bin/bash
# Install Tailscale: a private, encrypted network to reach this box from anywhere
# without opening any port on your router.
# Run:  sudo bash storage/setup-tailscale.sh
set -eu
[ "$(id -u)" = 0 ] || { echo "Run with sudo"; exit 1; }
. /etc/os-release
curl -fsSL "https://pkgs.tailscale.com/stable/debian/${VERSION_CODENAME}.noarmor.gpg" -o /usr/share/keyrings/tailscale-archive-keyring.gpg
curl -fsSL "https://pkgs.tailscale.com/stable/debian/${VERSION_CODENAME}.tailscale-keyring.list" -o /etc/apt/sources.list.d/tailscale.list
apt-get update -qq
apt-get install -y tailscale

if [ -x /etc/init.d/tailscaled ]; then
  update-rc.d tailscaled enable; service tailscaled start
else
  # Tailscale ships only a systemd unit; on sysvinit MX, start it from rc.local.
  CMD="/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock >/var/log/tailscaled.log 2>&1 &"
  grep -q tailscaled /etc/rc.local || sed -i "s#^exit 0#mkdir -p /run/tailscale\n$CMD\nexit 0#" /etc/rc.local
  grep -q tailscaled /etc/rc.local || { echo "Could not add tailscaled to /etc/rc.local"; exit 1; }
  mkdir -p /var/lib/tailscale /run/tailscale
  pgrep -x tailscaled >/dev/null || eval "$CMD"
  sleep 3
fi
echo "Open the link below and sign in:"
tailscale up
echo "This box's Tailscale address: $(tailscale ip -4)"
