# linux-server-hardening 🔐🐧
Enterprise-grade Linux server hardening baseline (SSH, firewall, sysctl, auditd, fail2ban) with safe-by-default scripts and CI checks.

![CI](https://img.shields.io/github/actions/workflow/status/<YOUR_GH_USER>/linux-server-hardening/ci.yml?branch=main)
![ShellCheck](https://img.shields.io/badge/ShellCheck-enabled-success)
![License](https://img.shields.io/badge/License-MIT-blue)

## Why this repo exists
This repository demonstrates practical, production-oriented Linux hardening:
- Real configs (not blogware)
- Idempotent scripts
- Backup + rollback
- “Dry-run first” workflow to prevent lockouts
- CIS-inspired controls mapping

## Supported targets
- Ubuntu 22.04/24.04
- Debian 12
> Note: Designed for typical cloud/VM servers. If you run routers, Kubernetes nodes, or specialized appliances, review sysctl and firewall settings carefully.

---

## What it hardens (baseline)
### SSH
- Disables root login
- Reduces brute-force surface (auth tries, timeouts)
- Strong defaults, includes safe guardrails to avoid lockout

### Firewall (UFW-based)
- Default deny incoming
- Allows SSH (port configurable)
- Optional allowlists for HTTP/HTTPS

### Kernel/sysctl
- Sensible network hardening defaults
- IPv4/IPv6 toggles are explicit

### auditd
- Core rules for identity, auth, sudoers, SSH config changes, time changes

### fail2ban
- sshd jail with sane defaults

---

## Safety model (IMPORTANT)
This repo follows a strict safety posture:
1) **Dry-run by default** (prints planned changes)
2) **Backups before modifications**
3) **Validation before restart** (e.g., `sshd -t`)
4) **Rollback capability**

---

## Quickstart
### 1) Clone
```bash
git clone https://github.com/<YOUR_GH_USER>/linux-server-hardening.git
cd linux-server-hardening
```
2) Install dependencies
make deps
3) Audit current system (no changes)
sudo make audit
4) Dry-run apply (recommended)
sudo make dry-run
5) Apply changes
sudo make apply
6) Rollback (if needed)
sudo make rollback
Configuration

Scripts support environment variables (override as needed):

SSH_PORT (default: 22)

ALLOW_PASSWORD_AUTH (default: false)
If false, script will configure SSH for key-based auth.
Set to true temporarily if you must keep password auth.

ALLOW_HTTP (default: false)

ALLOW_HTTPS (default: false)

Example:

sudo SSH_PORT=2222 ALLOW_HTTP=true ALLOW_HTTPS=true make apply
Compliance mapping

See: docs/02-cis-mapping.md

Repo signals (for recruiters)

This repo shows:

Security baselines

Operational discipline (backup/rollback)

CI quality gates (ShellCheck, shfmt, markdownlint)

Real-world defensive controls

License

MIT - see LICENSE.

Disclaimer

This is a baseline and not a substitute for a full security program. Always validate in a staging environment before production rollout.


---
