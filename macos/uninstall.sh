#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/mdm-onboard.log"
STATE_DIR="/var/lib/mdm-bootstrap"
STATE_PROFILES="${STATE_DIR}/installed_profiles.txt"

log() {
  local ts; ts="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "[$ts] $*" | tee -a "$LOG_FILE"
}

if [[ $EUID -ne 0 ]]; then
  echo "Re-running with sudo..."
  exec sudo -E "$0" "$@"
fi

log "Uninstall: removing profiles installed by bootstrap"

if [[ -f "$STATE_PROFILES" ]]; then
  tac "$STATE_PROFILES" | while read -r path; do
    [[ -z "$path" || ! -f "$path" ]] && continue
    id=$(/usr/libexec/PlistBuddy -c "Print :PayloadIdentifier" "$path" 2>/dev/null || true)
    if [[ -n "$id" ]]; then
      log "Removing profile by identifier: $id"
      if profiles help 2>&1 | grep -q "remove -identifier"; then
        /usr/bin/profiles remove -identifier "$id" || true
      else
        /usr/bin/profiles -R -p "$id" || true
      fi
    fi
  done
else
  log "No state file, skipping config removal list."
fi

# deleting mdmd env
log "Attempting to remove enrollment profile (if allowed)..."
if profiles help 2>&1 | grep -q "remove -type enrollment"; then
  /usr/bin/profiles remove -type enrollment || true
fi

log "Uninstall finished."
echo "✅ Uninstall done. See $LOG_FILE"
