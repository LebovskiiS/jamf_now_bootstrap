#!/usr/bin/env bash
set -euo pipefail

# Minimal interactive wrapper for bootstrap.sh
# - Detects macOS and suggests the matching mofileconfigs baseline
# - Prompts for optional Open Enrollment URL and Slack webhook
# - Writes .env and invokes bootstrap

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

ENV_FILE=".env"
BOOTSTRAP="./bootstrap.sh"

if [[ ! -x "$BOOTSTRAP" ]]; then
  echo "ERROR: bootstrap.sh not found or not executable. Run: chmod +x bootstrap.sh" >&2
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: macOS required." >&2
  exit 1
fi

# --- Detect macOS and suggest codename
product_ver="$(sw_vers -productVersion || true)"
major="${product_ver%%.*}"
detected="sequoia" # default to newest

case "$major" in
  15) detected="sequoia" ;;
  14) detected="sonoma"  ;;
  13) detected="ventura" ;;
  *)  detected="sequoia"  ;; # prefer latest baseline when unknown
esac

echo
echo "macOS detected: ${product_ver}  (suggested baseline: ${detected})"
echo "Supported baselines: sequoia (15), sonoma (14), ventura (13)"
echo "If your device is older than these, please upgrade to one of them (ideally the latest)."
echo

read -r -p "Baseline to use [sequoia/sonoma/ventura] (default: ${detected}): " CHOICE
CHOICE="${CHOICE:-$detected}"
case "$CHOICE" in
  sequoia|sonoma|ventura) ;;
  *) echo "Unknown choice '${CHOICE}', falling back to '${detected}'"; CHOICE="$detected" ;;
esac

BASELINE_DIR="mobileconfigs/macos/${CHOICE}"
if [[ ! -d "$BASELINE_DIR" ]]; then
  echo "ERROR: Baseline directory not found: ${BASELINE_DIR}" >&2
  echo "Make sure your .mobileconfig files exist under: ${BASELINE_DIR}" >&2
  exit 1
fi

# --- Optional enrollment URL (Jamf Now/Open Enrollment)
read -r -p "Open Enrollment URL (optional, e.g. https://go.jamfnow.com/XXXXX): " ENROLL_URL
ENROLL_URL="${ENROLL_URL:-}"

# --- Optional Slack webhook for success notice
read -r -p "Slack webhook URL (optional): " SLACK_WEBHOOK_URL
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

# --- Prepare .env (copy example if present)
if [[ -f ".env_example" && ! -f "$ENV_FILE" ]]; then
  cp .env_example "$ENV_FILE"
fi

# --- Write/overwrite keys safely
write_kv() {
  local key="$1" val="$2"
  touch "$ENV_FILE"
  if grep -qE "^${key}=" "$ENV_FILE"; then
    local esc; esc="$(printf '%s' "$val" | sed -e 's/[\/&]/\\&/g')"
    sed -i.bak -E "s|^(${key}=).*|\1${esc}|" "$ENV_FILE"
  else
    printf "%s=%s\n" "$key" "$val" >> "$ENV_FILE"
  fi
}

write_kv "ENROLL_PROFILE_URL" "${ENROLL_URL}"
write_kv "BASELINE_DIR" "${BASELINE_DIR}"
write_kv "SLACK_WEBHOOK_URL" "${SLACK_WEBHOOK_URL}"

echo
echo "[info] Wrote ${ENV_FILE} (values not echoed for safety)."

# --- Make hooks executable if present
chmod +x hooks/prebaseline.d/*.sh 2>/dev/null || true
chmod +x hooks/postbaseline.d/*.sh 2>/dev/null || true
chmod +x hooks/unenroll.d/*.sh 2>/dev/null || true

# --- Build args and run bootstrap
args=( "$BOOTSTRAP" --baseline-dir "$BASELINE_DIR" )
if [[ -n "${ENROLL_URL}" ]]; then
  args+=( --enroll-url "$ENROLL_URL" )
fi

echo "Running bootstrap..."
exec sudo -E "${args[@]}"
