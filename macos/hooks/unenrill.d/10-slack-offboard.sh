#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/mdm-onboard.log"
log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG_FILE"; }

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
  log "[slack] SLACK_WEBHOOK_URL not set, skip"
  exit 0
fi

host=$(scutil --get ComputerName 2>/dev/null || hostname)

payload=$(cat <<JSON
{"text":"MDM offboarding executed on *${host}*."}
JSON
)

curl -fsS -X POST -H 'Content-type: application/json' \
  --data "${payload}" \
  "$SLACK_WEBHOOK_URL" >/dev/null || true

log "[slack] offboard message sent"
