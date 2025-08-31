#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/mdm-onboard.log"
log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG_FILE"; }

if [[ "$(uname -m)" == "arm64" ]]; then
  if /usr/bin/pgrep oahd >/dev/null 2>&1; then
    log "[rosetta] already installed"
  else
    log "[rosetta] installing Rosetta"
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license 2>&1 | tee -a "$LOG_FILE" || true
  fi
else
  log "[rosetta] not needed on $(uname -m)"
fi
