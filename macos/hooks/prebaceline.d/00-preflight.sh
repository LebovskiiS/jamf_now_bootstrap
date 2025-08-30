#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/mdm-onboard.log"

log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG_FILE"; }

log "[preflight] start"
# Network check
if ! ping -c1 -t2 1.1.1.1 >/dev/null 2>&1; then
  log "[preflight] no network, abort"; exit 1
fi

# Disk space (need at least 5 GB)
avail_gb=$(df -g / | awk 'NR==2{print $4}')
if [[ "${avail_gb:-0}" -lt 5 ]]; then
  log "[preflight] low disk space (${avail_gb}G), abort"; exit 1
fi

# Power (optional): if on battery with < 20%, abort
if pmset -g batt 2>/dev/null | grep -q 'InternalBattery'; then
  pct=$(pmset -g batt | awk -F';' 'NR==2{print $2}' | tr -dc '0-9')
  if [[ "${pct:-100}" -lt 20 ]]; then
    log "[preflight] battery <20%, abort"; exit 1
  fi
fi

log "[preflight] ok"
