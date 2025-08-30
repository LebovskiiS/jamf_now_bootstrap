# Jamf Now Local Bootstrap (Manual Onboarding)

This repo provides a **manual, user‑initiated** bootstrap for macOS devices using **Jamf Now Open Enrollment**.
It installs the Jamf enrollment profile (if you provide an Open Enrollment URL) and applies a local security baseline via `.mobileconfig` profiles. It also enables core hardening (firewall, Gatekeeper, password policy, FileVault defer) and writes clear logs.

> If you need fully automated enrollment (DEP/ABM + Jamf Pro, zero‑touch), use the separate project:
> **[https://github.com/LebovskiiS/jamf\_pro\_bootstrap](https://github.com/LebovskiiS/jamf_pro_bootstrap)**

---

## What this is / isn’t

**This is:**

* A local bootstrap you run on a Mac to enroll via Jamf **Now** Open Enrollment and apply a baseline.
* OS‑aware: detects macOS 13/14/15 and picks the matching baseline folder.
* Extensible via hooks (pre/post baseline, and on unenroll).
* Safe logging and state tracking for clean uninstall.

**This is not:**

* Jamf Pro/DEP zero‑touch automation.
* A replacement for centrally managed policies/profiles in Jamf. It’s a “first mile” bootstrap.

---

## Repository layout

```
.
├─ bootstrap.sh              # main bootstrap (macOS only)
├─ uninstall.sh              # removes applied profiles; attempts MDM unenroll profile removal
├─ quickstart.sh             # interactive wrapper: detects OS, writes .env, runs bootstrap
├─ .env_example              # sample env file you copy to .env and edit
├─ hooks/
│  ├─ prebaseline.d/         # scripts run BEFORE baseline profile install (optional)
│  ├─ postbaseline.d/        # scripts run AFTER baseline profile install (optional)
│  └─ unenroll.d/            # scripts run during uninstall/unenroll (optional)
└─ mobileconfigs/
   └─ macos/
      ├─ sequoia/            # macOS 15 profiles (*.mobileconfig)
      ├─ sonoma/             # macOS 14 profiles (*.mobileconfig)
      └─ ventura/            # macOS 13 profiles (*.mobileconfig)
```

> If your device runs older macOS than 13 (Ventura), **please upgrade** to one of these three (ideally the latest).

---

## Requirements

* A Mac running macOS 13/14/15.
* (Optional) Jamf **Now** Open Enrollment link (e.g. `https://go.jamfnow.com/XXXXX`).
  Open Enrollment will prompt the user for name and code during profile install. The script cannot bypass this.
* Local admin rights (the scripts use `sudo`).
* (Optional) Slack Incoming Webhook URL for success notification.

---

## Quick start (recommended)

1. Put your `.mobileconfig` profiles into the appropriate OS folder under `mofileconfigs/macos/{sequoia|sonoma|ventura}/`.
2. Copy `.env_example` to `.env` if you want, or just use the interactive prompts.
3. Run:

   ```bash
   chmod +x quickstart.sh bootstrap.sh uninstall.sh
   ./quickstart.sh
   ```

   The helper will:

   * Detect your macOS version and suggest the matching baseline folder.
   * Prompt for **Open Enrollment URL** (optional).
   * Prompt for **Slack webhook** (optional).
   * Write/update `.env`.
   * Execute `bootstrap.sh` with the right arguments.

> Logs are written to **`/var/log/mdm-onboard.log`**.
> State of installed profile files is tracked at **`/var/lib/mdm-bootstrap/installed_profiles.txt`**.

---

## Manual usage

You can run the bootstrap directly:

```bash
sudo ./bootstrap.sh \
  --enroll-url "https://go.jamfnow.com/XXXXX" \
  --baseline-dir "mofileconfigs/macos/sequoia"
```

Or use environment variables (the script also reads `.env` if present):

```bash
ENROLL_PROFILE_URL="https://go.jamfnow.com/XXXXX" \
BASELINE_DIR="mofileconfigs/macos/sonoma" \
sudo -E ./bootstrap.sh
```

**Variables**

* `ENROLL_PROFILE_URL` — Jamf Now Open Enrollment link (optional).
* `BASELINE_DIR` — path to the folder containing your `.mobileconfig` baseline.
* `SLACK_WEBHOOK_URL` — optional Slack Incoming Webhook for a success notice.

---

## What the bootstrap does

* Verifies macOS and chooses a baseline directory (Sequoia/Sonoma/Ventura).
* Installs the **MDM enrollment** `.mobileconfig` (if `ENROLL_PROFILE_URL` provided).
  Jamf Now may prompt for name/code during installation.
* Installs all `.mobileconfig` files in your chosen baseline directory.
* Enables:

  * Application Firewall (`socketfilterfw --setglobalstate on`)
  * Gatekeeper (`spctl --master-enable`)
  * Local password policy (`pwpolicy`) — min length 12, mixed case, number, symbol
  * FileVault deferral (`fdesetup enable -defer`) if not already enabled
* Logs actions and prints installed profile identifiers.
* Optionally sends a Slack success message (if `SLACK_WEBHOOK_URL` is set).

---

## Hooks (optional)

You can drop your own scripts to extend behavior. The bootstrap will run them if present:

* `hooks/prebaseline.d/*.sh` — run **before** installing baseline profiles.
  *Example:* ensure Rosetta, install CLI dependencies, preflight checks.

* `hooks/postbaseline.d/*.sh` — run **after** installing baseline profiles.
  *Example:* “assert” that a setting took effect, notify Slack, start agents.

* `hooks/unenroll.d/*.sh` — run during `uninstall.sh`.
  *Example:* stop agents, revoke local certificates, wipe temp artifacts.

Make scripts executable:

```bash
chmod +x hooks/prebaseline.d/*.sh hooks/postbaseline.d/*.sh hooks/unenroll.d/*.sh
```

You’ll find commented examples in the repo; copy them without the `.example` suffix, adjust, and make executable.

---

## Uninstall / clean up

```bash
sudo ./uninstall.sh
```

This will:

* Remove the configuration profiles that `bootstrap.sh` applied (using tracked state).
* Attempt to remove the MDM **enrollment** profile (only if the OS allows it).
* Run any `hooks/unenroll.d/*.sh` scripts you’ve provided.

---

## Logging and state

* **Log file:** `/var/log/mdm-onboard.log`
* **State directory:** `/var/lib/mdm-bootstrap/`

  * `installed_profiles.txt` holds the list of applied profile file paths to allow clean removal.

---

## Secrets and configuration

* **.env**: put your local values in `.env` (never commit secrets).
  A `.env_example` is included to copy:

  ```bash
  cp .env_example .env
  # then edit .env
  ```

* **Slack**: provide `SLACK_WEBHOOK_URL` if you want a success notification.

> You can integrate a secrets manager later; this manual bootstrap ships with simple `.env` configuration to keep the setup straightforward.

---

## Limitations

* Jamf **Now** Open Enrollment requires user interaction (name/code) inside the profile install dialog; this is expected.
* This bootstrap focuses on macOS. Windows/Linux flows are out of scope here.
* For truly zero‑touch, move to Jamf Pro/DEP and use the dedicated project:
  [https://github.com/LebovskiiS/jamf\_pro\_bootstrap](https://github.com/LebovskiiS/jamf_pro_bootstrap)

---

## FAQ

**Where do I get the Open Enrollment URL?**
From your Jamf Now Open Enrollment page (e.g., `https://go.jamfnow.com/XXXXX`). That link downloads a `.mobileconfig`. The script automates downloading and installing it, but Jamf may still prompt for user attributes (name/code).

**Do I need to change anything for different macOS versions?**
No. `quickstart.sh` detects 13/14/15 and points `bootstrap.sh` to the matching baseline folder under `mofileconfigs/macos/`.

**Can I add EDR/VPN/agent setup?**
Yes, put that logic into `hooks/postbaseline.d/*.sh` so it runs after baseline profiles are applied.

**Where can I see what happened?**
Read `/var/log/mdm-onboard.log`. The last lines include the list of installed profile identifiers.

---

## Contributing

* Keep `.mobileconfig` profiles under the correct OS folder:
  `mofileconfigs/macos/{sequoia|sonoma|ventura}/`
* Avoid committing real secrets; use `.env_example` as a template.
* Prefer adding custom behaviors via hooks, not by forking the core scripts.

---

## License

MIT (or your preferred license).
