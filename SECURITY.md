# SECURITY.md

## Security Policy

### Reporting a Vulnerability

Please email **[sergei@pharmacyhub.com](mailto:sergei@pharmacyhub.com)** with the subject `SECURITY`. Include:

* Affected files/components (e.g., `bootstrap.sh`, `uninstall.sh`, `quickstart.sh`, any `mobileconfig` payloads, and scripts under `hooks/`).
* Exact macOS version and baseline used (e.g., Sequoia/Sonoma/Ventura).
* Reproduction steps and a minimal proof-of-concept.
* Relevant log excerpts from `/var/log/mdm-onboard.log`.

**Do not** file public GitHub issues for security problems.

**Response targets**

* Acknowledgment within **72 hours**.
* Status updates at least **weekly** until resolution.
* Coordinated disclosure is preferred; typical fix ETA is **30 days** depending on severity.

**Scope**
This project’s scripts and assets only: `bootstrap.sh`, `uninstall.sh`, `quickstart.sh`, `mobileconfigs/`, `hooks/`, and repository automation. Issues in Jamf/Apple/third‑party services (Slack, Vault, etc.) are out of scope.

**Safe Harbor**
Good‑faith security research conducted under this policy will not be pursued legally. Avoid data exfiltration; use test data where possible.

---

# SUPPORT.md

## Getting Help

* Read `README.md` first.
* Open a GitHub Issue with the appropriate template (bug or feature).
* For private matters (logs with sensitive data, security concerns), email **[sergei@pharmacyhub.com](mailto:sergei@pharmacyhub.com)**.

## What to Include

* macOS version and chosen baseline (Sequoia/Sonoma/Ventura).
* Exact command run (e.g., `sudo ./bootstrap.sh …`).
* Full log from `/var/log/mdm-onboard.log` (redact secrets).
* Contents of your `.env` **example** (redacted) or values you set interactively.

## Service Levels

This is best‑effort support. We triage critical enrollment breakages first, then baseline/profile issues, then enhancements.

---

# CONTRIBUTING.md

## Ground Rules

Be respectful. Keep secrets out of the repo. Follow the security policy when reporting vulnerabilities.

## How to Contribute

1. Fork the repo and create a feature branch.
2. Make focused changes; update docs and `.env_example` if you add variables.
3. Run linting locally (see below) and test on a supported macOS version (13/14/15).
4. Open a Pull Request using the provided template.

## Coding Style (Bash)

* Use `#!/usr/bin/env bash` and `set -euo pipefail`.
* Quote variables and use `$(…)` for command substitution.
* Keep logging consistent via the shared `log()` helper.
* Prefer functions; avoid global side effects.

### Linting & Formatting

* [ShellCheck](https://www.shellcheck.net/): `shellcheck **/*.sh`
* [shfmt](https://github.com/mvdan/sh): `shfmt -d -i 2 -ci -s .`

## Directory Layout

```
mobileconfigs/
  macos/
    ventura/
    sonoma/
    sequoia/
hooks/
  postbaseline.d/   # runs after baseline profiles are installed
  uninstall.d/      # runs during uninstall
```

## Conventional Commits

Examples: `feat: add Gatekeeper hardening`, `fix: correct profiles install fallback`, `docs: update README for quickstart`.

## PR Checklist

* [ ] Tests performed on at least one supported macOS version.
* [ ] Updated docs and `.env_example` as needed.
* [ ] No secrets committed; `.env` is ignored.
* [ ] CI/lint passes.

---

# .github/ISSUE\_TEMPLATE/bug\_report.md

```markdown
---
name: Bug report
about: Something didn’t work as expected
labels: bug
---

**Describe the bug**
A clear and concise description of the issue.

**Environment**
- macOS version:
- Baseline used (sequoia/sonoma/ventura):
- Command run:

**Logs**
Attach `/var/log/mdm-onboard.log` (or paste relevant excerpts).

**Steps to Reproduce**
1.
2.
3.

**Expected behavior**

**Additional context**
```

---

# .github/ISSUE\_TEMPLATE/feature\_request.md

```markdown
---
name: Feature request
about: Suggest an idea for this project
labels: enhancement
---

**Problem to solve**

**Proposed solution**

**Alternatives considered**

**Additional context**
```

---

# .github/ISSUE\_TEMPLATE/security\_vulnerability.md

```markdown
---
name: Security vulnerability (private)
about: Do not use this template for public issues
labels: security
---

Please do **not** disclose vulnerabilities publicly. Email **sergei@pharmacyhub.com** with full details (see SECURITY.md). You may reference this issue privately if needed.
```

---

# .github/PULL\_REQUEST\_TEMPLATE.md

```markdown
## Summary

Describe what this PR changes and why.

## Testing
- macOS version(s) tested:
- Baseline(s):
- Commands used:

## Checklist
- [ ] Docs updated (`README.md`, `SECURITY.md`, `SUPPORT.md`, `.env_example` if needed)
- [ ] Lint/format passes (ShellCheck, shfmt)
- [ ] No secrets committed
- [ ] Linked issues (if any)
```
