#!/bin/sh
# Firefox tuned for 2 GB RAM: fewer content processes, no disk cache, no telemetry,
# uBlock Origin preinstalled. Applied system-wide via an enterprise policy file.
# Run:  sudo sh debloat/firefox-lite.sh
# Undo: sudo rm /etc/firefox/policies/policies.json
set -e
[ "$(id -u)" = 0 ] || { echo "run with: sudo sh $0"; exit 1; }

apt-get install -y firefox

mkdir -p /etc/firefox/policies
cat > /etc/firefox/policies/policies.json <<'EOF'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DontCheckDefaultBrowser": true,
    "ExtensionSettings": {
      "uBlock0@raymondhill.net": {
        "installation_mode": "normal_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
      }
    },
    "Preferences": {
      "dom.ipc.processCount":                     { "Value": 2,     "Status": "default" },
      "browser.sessionhistory.max_total_viewers": { "Value": 0,     "Status": "default" },
      "browser.cache.disk.enable":                { "Value": false, "Status": "default" },
      "browser.sessionstore.interval":            { "Value": 60000, "Status": "default" },
      "browser.newtabpage.activity-stream.feeds.topsites": { "Value": false, "Status": "default" },
      "browser.newtabpage.activity-stream.feeds.section.topstories": { "Value": false, "Status": "default" }
    }
  }
}
EOF
echo "Done. uBlock Origin installs on Firefox's first launch."
