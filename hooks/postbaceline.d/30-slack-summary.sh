#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/mdm-onboard.log"
log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG_FILE"; }

# Collect info
host=$(scutil --get ComputerName 2>/dev/null || hostname)
osv=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
serial=$(/usr/sbin/ioreg -l | awk -F\" '/IOPlatformSerialNumber/{print $4}' 2>/dev/null || echo "unknown")
fv=$(/usr/bin/fdesetup status 2>/dev/null | tr -d '\n' || echo "unknown")

# List installed profile identifiers
ids=$(/usr/bin/profiles list -type configuration 2>/dev/null \
  | awk -F"identifier: " '/identifier: /{print $2}' \
  | awk '{print $1}' | sed 's/^/- /')

log "[summary] host=${host}, macOS=${osv}, serial=${serial}"
log "[summary] filevault: ${fv}"
log "[summary] profiles:\n${ids}"

# Slack (optional)
if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
  msg="MDM onboarding finished on *${host}* (macOS ${osv}, SN ${serial}).\n*FileVault:* ${fv}\n*Profiles installed:*\n${ids:-none}"
  payload=$(python - <<'PY'
import json, os, sys
msg=os.environ.get("MSG","")
print(json.dumps({"text": msg}))
PY
)
  MSG="$msg" curl -fsS -X POST -H 'Content-type: application/json' \
    --data "${payload}" \
    "$SLACK_WEBHOOK_URL" >/dev/null || true
  log "[slack] summary sent"
else
  log "[slack] webhook not set, skip"
fi
