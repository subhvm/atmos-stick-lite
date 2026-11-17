#!/bin/bash
# Storage health check with phone alerts via ntfy (https://ntfy.sh, free, no account).
# Checks: both cards mounted, neither over FULL_PCT, last backup OK within 26 h,
# FileBrowser running. Alerts only when something CHANGES (new problem / fixed).
#
# Setup (as your normal user, no sudo):
#   1. Pick a long random channel name and save it OUTSIDE the repo (anyone who
#      knows the name can read the alerts):
#        mkdir -p ~/.config && echo "NTFY_TOPIC=stick-$(head -c12 /dev/urandom | base64 | tr -dc a-zA-Z0-9)" > ~/.config/stick-health.conf
#   2. Install the ntfy app on your phone and subscribe to that channel name.
#   3. Test:   storage/health-check.sh --test
#   4. Run every 15 minutes:
#        (crontab -l 2>/dev/null; echo "*/15 * * * * $PWD/storage/health-check.sh") | crontab -
. "$(dirname "$0")/config.sh"
CONF="$HOME/.config/stick-health.conf"
[ -f "$CONF" ] && . "$CONF"
BACKUP_LOG="${BACKUP_LOG:-$HOME/cloud-backup.log}"   # where backup.sh writes (see its crontab line)
FULL_PCT="${FULL_PCT:-90}"
NTFY_SERVER="${NTFY_SERVER:-https://ntfy.sh}"
STATE="$HOME/.cache/stick-health.state"

notify() {  # $1 title, $2 message, $3 priority, $4 tag
  [ -n "$NTFY_TOPIC" ] || { echo "$1: $2"; return; }
  curl -fsS -m 20 -H "Title: $1" -H "Priority: $3" -H "Tags: $4" \
       -d "$2" "$NTFY_SERVER/$NTFY_TOPIC" >/dev/null
}

if [ "$1" = "--test" ]; then
  notify "Stick health check" "Test alert - notifications work." default white_check_mark
  echo "Sent test to ${NTFY_TOPIC:-<no topic set, printed instead>}"; exit
fi

problems=()
for m in "$MAIN" "$SPARE"; do
  if ! mountpoint -q "$m"; then
    problems+=("$m is not mounted")
  else
    pct=$(df --output=pcent "$m" | tail -1 | tr -dc 0-9)
    [ "$pct" -ge "$FULL_PCT" ] && problems+=("$m is ${pct}% full")
  fi
done

if [ -f "$BACKUP_LOG" ]; then           # no log yet = backup never ran; nothing to judge
  last=$(grep -E ' (OK|SKIPPED|ERROR)' "$BACKUP_LOG" | tail -1)
  last_ok=$(grep ' OK: ' "$BACKUP_LOG" | tail -1 | cut -c1-19)
  case "$last" in *SKIPPED*|*ERROR*) problems+=("last backup failed: ${last:20}") ;; esac
  if [ -z "$last_ok" ] || [ $(( $(date +%s) - $(date -d "$last_ok" +%s) )) -gt 93600 ]; then
    problems+=("no successful backup in over 26 hours")
  fi
fi

pgrep -x filebrowser >/dev/null || problems+=("FileBrowser is not running")

# Compare with the previous run and alert only on changes.
mkdir -p "$(dirname "$STATE")"; touch "$STATE"
now=$(printf '%s\n' "${problems[@]}" | sed '/^$/d' | sort)
new=$(comm -13 "$STATE" <(echo "$now") | sed '/^$/d')
fixed=$(comm -23 "$STATE" <(echo "$now") | sed '/^$/d')
[ -n "$new" ]   && notify "Stick: problem" "$new" high warning
[ -n "$fixed" ] && notify "Stick: fixed" "$fixed" default white_check_mark
echo "$now" > "$STATE"
