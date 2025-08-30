macOS MDM Bootstrap (Manual, Jamf-compatible)

This repo provides a manual/local bootstrap for macOS endpoints that installs your .mobileconfig baselines and (optionally) an Open Enrollment profile (e.g., Jamf Now link). It also applies baseline hardening and can notify Slack.

This version is designed for manual, on-device installation (not zero-touch).
For an automated variant, see: https://github.com/LebovskiiS/jamf_pro_bootstrap

Fork/copy it, or rename .env_example → .env and set your values. Optional integrations: Slack and Vault 🔒🛡️

Supported OS / Baselines

Sequoia (macOS 15.x) → mofileconfigs/macos/sequoia

Sonoma (macOS 14.x) → mofileconfigs/macos/sonoma

Ventura (macOS 13.x) → mofileconfigs/macos/ventura

If your device runs an earlier macOS, please upgrade to one of these (preferably the latest).

Each baseline directory should contain your exported .mobileconfig files (e.g., from Jamf’s Compliance Editor).
Use numeric prefixes to control install order, for example:

01-passwords.mobileconfig
02-filevault.mobileconfig
03-firewall.mobileconfig

Repository Layout
.
├─ bootstrap.sh                 # main bootstrap (reads .env and/or flags)
├─ uninstall.sh                 # rollback (removes profiles installed by bootstrap)
├─ quickstart.sh                # interactive launcher (prompts -> writes .env -> runs bootstrap)
├─ .env_example                 # environment template to copy to .env
├─ hooks/
│  └─ postbaseline.d/
│     └─ 10-edr.sh.example     # optional post-baseline hook (e.g., install EDR/VPN/pkg)
└─ mobileconfigs/
   └─ macos/
      ├─ sequoia/
      │  ├─ 01-passwords.mobileconfig
      │  ├─ 02-filevault.mobileconfig
      │  └─ 03-firewall.mobileconfig
      ├─ sonoma/
      └─ ventura/

Requirements

macOS (13/14/15) with built-ins: profiles, curl, spctl, fdesetup, softwareupdate, systemsetup

sudo privileges (the scripts will re-exec with sudo if needed)

On modern macOS, installing configuration profiles may require user approval in System Settings → Profiles (Apple platform behavior).

Quick Start (Interactive)

Place your .mobileconfig files under the matching baseline:

mofileconfigs/macos/sequoia/ (macOS 15)

mofileconfigs/macos/sonoma/ (macOS 14)

mofileconfigs/macos/ventura/ (macOS 13)

Run the launcher:

chmod +x quickstart.sh bootstrap.sh uninstall.sh
./quickstart.sh


What happens:

Detects your macOS and proposes the correct baseline (sequoia/sonoma/ventura)

Prompts for the Open Enrollment URL (Jamf Now “go.jamfnow.com/…”, optional)

Prompts for Slack webhook (optional)

Writes a .env with your choices

Runs bootstrap.sh with the chosen baseline

Quick Start (Manual)

Prefer to set values yourself?

cp .env_example .env
# Edit .env (set ENROLL_PROFILE_URL, BASELINE_DIR, SLACK_WEBHOOK_URL)

sudo ./bootstrap.sh \
  --baseline-dir mofileconfigs/macos/sonoma \
  --enroll-url "https://go.jamfnow.com/XXXXX"


Environment variables read by bootstrap.sh:

ENROLL_PROFILE_URL="https://go.jamfnow.com/XXXXX"  # optional Open Enrollment URL
BASELINE_DIR="mofileconfigs/macos/sequoia"         # or sonoma/ventura
SLACK_WEBHOOK_URL=""                                # optional Slack notifications


Jamf Now Open Enrollment URLs may present a UI asking for org name/code; that step is handled by Apple’s UI after the profile is installed.

What the Bootstrap Does

Detects macOS version and selects/uses the baseline directory.

Optional: downloads and installs the enrollment .mobileconfig from your Open Enrollment URL.

Installs each .mobileconfig found in the baseline directory (alphabetical order).

Enables Firewall, Gatekeeper, system updates, and NTP.

Logs everything to /var/log/mdm-onboard.log.
Tracks installed profile paths in /var/lib/mdm-bootstrap/installed_profiles.txt (used by uninstall.sh to derive identifiers).

Sends a Slack success message if SLACK_WEBHOOK_URL is set.

Uninstall / Rollback
sudo ./uninstall.sh


Reads /var/lib/mdm-bootstrap/installed_profiles.txt (created by the bootstrap)

Resolves each profile’s PayloadIdentifier and removes it

Attempts to remove the enrollment profile where allowed by the OS

Logs & Troubleshooting

Main log: /var/log/mdm-onboard.log

Installed profile paths list: /var/lib/mdm-bootstrap/installed_profiles.txt

List installed profiles:

/usr/bin/profiles list -type configuration


Common checks:

Ensure .mobileconfig files exist in the chosen baseline directory.

If the enrollment profile requires user approval, complete that in System Settings → Profiles.

If FileVault deferral warns about SecureToken, log in with a SecureToken admin and enable FileVault.

Optional Integrations
Slack

Set SLACK_WEBHOOK_URL in .env (or provide it via quickstart.sh). The bootstrap will post a simple success message when onboarding completes. 🔒🛡️

HashiCorp Vault (optional)

If you don’t want secrets in .env, use a wrapper or a hooks/postbaseline.d/* script to fetch secrets from Vault at runtime and export them as env variables for the bootstrap. 🔒

.gitignore

Recommended entries:

# local secrets and logs
.env
*.log
/var/log/mdm-onboard.log

# macOS detritus
.DS_Store

# editor/IDE
.idea/
.vscode/


Commit .env_example only. Do not commit real secrets. 🔒

Limitations

This project does not create or manage an MDM server; it installs local profiles and (optionally) your enrollment profile.

Profile installs/removals may require user approval depending on macOS version and device state.

Advanced controls (PPPC, system extension approvals, FV escrow) are best managed by your MDM server.

FAQ

Do I need Python or extra dependencies?
No, everything is pure Bash using macOS built-ins.

Can I pin a specific baseline?
Yes: run with --baseline-dir mofileconfigs/macos/<sequoia|sonoma|ventura> or set BASELINE_DIR in .env.

Can I deploy EDR/VPN silently?
Yes. Add a signed installer step in hooks/postbaseline.d/ (see 10-edr.sh.example) and handle approvals via your profiles/MDM.

Where do I get the enrollment URL?
From your Jamf Now Open Enrollment page (e.g., https://go.jamfnow.com/XXXXX). Paste that into quickstart.sh or .env.