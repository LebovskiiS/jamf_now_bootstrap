#!/usr/bin/env bash
set -euo pipefail

# =========================
# Minimal MDM bootstrap for macOS (Jamf Now friendly)
# - Detects OS codename -> picks baseline dir
# - Installs MDM enroll profile if --enroll-url provided
# - Applies *.mobileconfig baseline
# - Adds a few local hardening toggles (firewall, gatekeeper, pw policy, FV defer)
# Logs: /var/log/mdm-onboard.log
# =========================

LOG_FILE="/var/log/mdm-onboard.log"
STATE_DIR="/var/lib/mdm-bootstrap"
STATE_PROFILES="${STATE_DIR}/installed_profiles.txt"

mkdir -p "$(dirname "$LOG_FILE")" "$STATE_DIR"
touch "$STATE_PROFILES"

log() {
  local ts; ts="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "[$ts] $*" | tee -a "$LOG_FILE"
}

# Fail-fast logging
trap 'code=$?; log "ERROR at line $LINENO (exit $code)"; exit $code' ERR

require_root() {
  if [[ ${EUID:-0} -ne 0 ]]; then
    echo "Re-running with sudo..."
    exec sudo -E "$0" "$@"
  fi
}

usage() {
  cat <<EOF
Usage: sudo $0 [--enroll-url <url>] [--baseline-dir <dir>]
Env: ENROLL_PROFILE_URL, BASELINE_DIR, FORCE_OS (sequoia|sonoma|ventura|common)
Notes:
 - .env will be loaded (if present), but CLI flags take precedence.
 - Baseline dir defaults to mobileconfigs/macos/<codename> or .../common.
EOF
}

# -------------------------
# Load .env first (CLI flags will override)
# -------------------------
if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env
fi

# Defaults from env (may be overridden by CLI)
ENROLL_URL="${ENROLL_PROFILE_URL:-${ENROLL_URL:-}}"
BASELINE_DIR="${BASELINE_DIR:-}"

# -------------------------
# Parse CLI args
# -------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --enroll-url)  ENROLL_URL="$2"; shift 2 ;;
    --baseline-dir) BASELINE_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

require_root "$@"

# -------------------------
# OS autodetect (macOS only)
# -------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  log "ERROR: This bootstrap is for macOS only."
  exit 1
fi

product_ver="$(/usr/bin/sw_vers -productVersion || true)"
major="${product_ver%%.*}"

# Allow forced codename via env for testing (FORCE_OS=sequoia/sonoma/ventura/common)
if [[ -n "${FORCE_OS:-}" ]]; then
  codename="${FORCE_OS}"
else
  case "$major" in
    15) codename="sequoia" ;;
    14) codename="sonoma"  ;;
    13) codename="ventura" ;;
    *)  codename="common"  ;;
  esac
fi

# Choose baseline dir (prefer OS-specific, fallback to common)
default_baseline="mobileconfigs/macos/${codename}"
if [[ -z "${BASELINE_DIR}" ]]; then
  if [[ -d "$default_baseline" ]]; then
    BASELINE_DIR="$default_baseline"
  else
    BASELINE_DIR="mobileconfigs/macos/common"
  fi
fi

log "macOS version: ${product_ver} (codename=${codename})"
log "Baseline dir:  ${BASELINE_DIR}"

# -------------------------
# Helpers
# -------------------------
install_profile() {
  local file="$1"
  # Try modern syntax first (Ventura+), fallback to legacy
  if /usr/bin/profiles help 2>&1 | grep -q "install -type"; then
    /usr/bin/profiles install -type configuration -path "$file"
  else
    /usr/bin/profiles -I -F "$file"
  fi
}

list_installed_identifiers() {
  /usr/bin/profiles list -type configuration 2>/dev/null \
    | awk -F"identifier: " '/identifier: /{print $2}' \
    | awk '{print $1}'
}

# -------------------------
# Enroll MDM (optional)
# -------------------------
if [[ -n "${ENROLL_URL:-}" ]]; then
  tmp="/tmp/enroll.mobileconfig"
  log "Downloading MDM enrollment profile from: ${ENROLL_URL}"
  /usr/bin/curl -fsSL -o "$tmp" "$ENROLL_URL"
  log "Installing MDM enrollment profile..."
  install_profile "$tmp" || { log "ERROR: failed to install enrollment profile"; exit 1; }
  echo "$tmp" >> "$STATE_PROFILES"
  log "MDM enrollment profile installed."
else
  log "No ENROLL_PROFILE_URL provided; skipping MDM enrollment."
fi

# -------------------------
# Apply baseline *.mobileconfig
# -------------------------
if [[ -d "$BASELINE_DIR" ]]; then
  shopt -s nullglob
  # Install in lexical order -> supports 01-*, 02-*, ...
  for p in "$BASELINE_DIR"/*.mobileconfig; do
    log "Installing baseline profile: $(basename "$p")"
    install_profile "$p" || { log "ERROR: failed to install $p"; exit 1; }
    echo "$p" >> "$STATE_PROFILES"
  done
  shopt -u nullglob
else
  log "WARNING: Baseline dir not found: $BASELINE_DIR"
fi

# -------------------------
# Lightweight local hardening (best-effort)
# -------------------------
log "Enabling firewall..."
/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on || true

log "Enabling Gatekeeper..."
/usr/sbin/spctl --master-enable || true

log "Applying local password policy (min 12 chars, mixed case, number, symbol)..."
/usr/bin/pwpolicy -setglobalpolicy "minChars=12 requiresAlpha=1 requiresNumeric=1 requiresMixedCase=1 requiresSymbol=1" || true

log "Checking FileVault status..."
if /usr/bin/fdesetup status | grep -q "FileVault is On"; then
  log "FileVault already enabled."
else
  log "Deferring FileVault enable to next login..."
  /usr/bin/fdesetup enable -defer /var/root/fvdefer.plist || log "WARN: fdesetup defer failed (needs SecureToken user)."
fi

# -------------------------
# Summary
# -------------------------
log "Installed config profile identifiers:"
list_installed_identifiers | tee -a "$LOG_FILE" || true

log "Bootstrap finished."
echo
echo "✅ Done. Log: $LOG_FILE"
