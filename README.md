<div align="center">

# 🔐 Linux Server Hardening Baseline
### Enterprise-grade OS hardening for Ubuntu 22.04 / 24.04 Cloud deployments.

[![CI Pipeline](https://img.shields.io/github/actions/workflow/status/welldefreitas/linux-server-hardening/ci.yml?style=for-the-badge)](https://github.com/welldefreitas/linux-server-hardening/actions)![ShellCheck](https://img.shields.io/badge/ShellCheck-enabled-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

**Goal:** Provide a safe, repeatable, and automated security baseline for cloud VMs with built-in rollback and dry-run capabilities.

</div>

---

## 🎯 Why this repo exists

This repository is designed to prove **real** Linux hardening ability in a way recruiters and clients recognize:
- **Operational safety:** Dry-run first, backups before changes, and `sshd -t` validation.
- **Repeatable baseline:** Deterministic application via templates + scripts.
- **Cloud-aware:** Designed for cloud environments (Security Groups + UFW host firewall).
- **Defense-in-depth:** SSH + Firewall + Kernel knobs + Auditd + Fail2ban + Automated Patching.

> **Supported Targets:** Optimized and validated primarily for **Ubuntu 22.04 / 24.04** (cloud images). Best-effort support for Debian-like systems. Always validate in staging before production rollout.

---

## 🛡️ What this baseline hardens

- **1️⃣ Automatic Security Patching:** Enables APT unattended upgrades (security origins only).
- **2️⃣ SSH Hardening:** Disables root login, enforces key-first posture, and limits brute-force surface.
- **3️⃣ Firewall (UFW):** Default deny incoming, explicitly allows SSH, with optional web ports.
- **4️⃣ Kernel (sysctl):** RP filter, SYN cookies, and ICMP redirect protections.
- **5️⃣ Accountability (auditd):** Watches identity files, sudoers, SSH configs, and auth logs.
- **6️⃣ Brute Force Defense (fail2ban):** SSH jail enabled with sensible defaults.

- ---

## 🛑 Safety model (IMPORTANT)

This repo follows strict operational guardrails to prevent accidental lockouts or server breakage:
1. **Dry-run supported** (`DRY_RUN=1`) — Prints intended actions without changing the system.
2. **Backups created first** — Automatic snapshots saved under `.backups/<timestamp>/`.
3. **Config validation** — `sshd -t` runs to validate syntax before restarting the SSH service.
4. **Rollback available** — One command to restore key files from the latest backup snapshot.

---

## 🚀 Quickstart (Recommended Workflow)

**1) Clone the repository**
```bash
git clone https://github.com/welldefreitas/linux-server-hardening.git
cd linux-server-hardening
```
**2) Install dependencies**
```bash
make deps
```

**3) Audit current state (no changes)**
```bash
sudo make audit
```

**4) Dry-run the baseline (recommended)**
```bash
sudo make dry-run
```

**5) Apply baseline**
```bash
sudo make apply
```

**6) Emergency Rollback (if needed)**
```bash
sudo make rollback
```

---

## 🎭 Profiles

Profiles are environment configuration files loaded by `scripts/apply.sh` to adapt the firewall and SSH rules based on the server's role.

### 🌐 Profile: `cloud-web` (Web Server)
- **Firewall:** Opens SSH + 80 (HTTP) + 443 (HTTPS).
- **SSH:** Disables SSH forwarding (safer for web servers).
```bash
sudo PROFILE=cloud-web make dry-run
sudo PROFILE=cloud-web make apply
```

### 🏰 Profile: `bastion` (Jump Host)
- **Firewall:** Opens SSH ONLY.
- **SSH:** Enables TCP forwarding for ProxyJump. Keeps agent forwarding disabled by default.
```bash
sudo PROFILE=bastion make dry-run
sudo PROFILE=bastion make apply
```

> **⚠️ Cloud Security Group Checklist:** Host firewall (UFW) is not a replacement for Cloud Security Groups (AWS/GCP/Azure). You should use both! Never open port 22 to `0.0.0.0/0` at the SG level.

## 📁 Repository Structure 

```text
linux-server-hardening/
├── .github/
│   └── workflows/
│       └── ci.yml                     # CI: ShellCheck, shfmt, sanity checks (quality gates)
│
├── docs/
│   ├── 01-quickstart.md               # Operator quickstart + lockout prevention checklist
│   ├── 02-cis-mapping.md              # High-level CIS-inspired mapping (not full CIS automation)
│   └── 11-rollback.md                 # Rollback procedure + what gets restored
│
├── profiles/
│   ├── README.md                      # Profiles overview + Security Group recommendations
│   ├── cloud-web.env                  # Web server profile: SSH + 80/443; forwarding disabled
│   └── bastion.env                    # Bastion profile: SSH only; TCP forwarding enabled
│
├── hardening/
│   ├── apt/
│   │   ├── 20auto-upgrades            # Enables APT periodic actions (update/download/clean)
│   │   └── 50unattended-upgrades      # Unattended upgrades policy (AUTO_REBOOT toggle)
│   │
│   ├── ssh/
│   │   └── sshd_config.d/
│   │       └── 99-hardening.conf      # SSH hardening drop-in template (placeholders injected)
│   │
│   ├── sysctl.d/
│   │   └── 99-hardening.conf          # Kernel/network hardening baseline (sysctl --system)
│   │
│   ├── auditd/
│   │   └── rules.d/
│   │       └── 99-hardening.rules     # Audit rules: identity/sudoers/sshd/time/auth logs
│   │
│   └── fail2ban/
│       └── jail.d/
│           └── sshd.local             # fail2ban sshd jail: brute-force protection defaults
│
├── scripts/
│   ├── common.sh                      # Shared helpers: logging, backups, idempotent writes
│   ├── install-deps.sh                # Installs packages (Ubuntu 22.04/24.04 cloud focus)
│   ├── backup.sh                      # Creates snapshot backups under .backups/<timestamp>/
│   ├── apply.sh                       # Orchestrates baseline + profile loading + guardrails
│   ├── audit.sh                       # Audits baseline signals (SSH/UFW/sysctl/auditd/f2b/UA)
│   └── rollback.sh                    # Restores latest backup + restarts services safely
│
├── .editorconfig                      # Editor consistency (indentation, line endings)
├── .gitignore                         # Ignores backups and OS artifacts
├── .shellcheckrc                      # ShellCheck configuration (strict posture)
├── CHANGELOG.md                       # Version history (enterprise signal)
├── LICENSE                            # MIT license
├── Makefile                           # Developer/operator UX: deps, audit, dry-run, apply, rollback
├── README.md                          # Main documentation (quickstart + profiles + design)
└── security.md                        # Threat model + mitigations + operational risks
```
## ⚙️ Configuration (Env Vars)

You can override defaults via environment variables:
- `PROFILE`: Loads `profiles/<PROFILE>.env`.
- `DRY_RUN`: Set to `1` to print intended actions.
- `SSH_PORT`: Default `22`.
- `ALLOW_PASSWORD_AUTH`: Default `false` (Key-based only).
- `ALLOW_HTTP` / `ALLOW_HTTPS`: Default `false`.
- `AUTO_REBOOT`: Default `false` (Toggle for unattended upgrades).

**Example manual override:**
```bash
sudo SSH_PORT=2222 ALLOW_HTTP=true AUTO_REBOOT=false make apply
```


---

## ⚙️ Configuration Reference (Env Vars)

You can override core options via environment variables (or inside `profiles/*.env`).

**Core Options:**
- `PROFILE` (default: empty): Loads `profiles/<PROFILE>.env` if set.
- `DRY_RUN` (default: `0`): Set to `1` to print intended actions without applying.

**SSH Configuration:**
- `SSH_PORT` (default: `22`): SSH listen port.
- `ALLOW_PASSWORD_AUTH` (default: `false`): If false, SSH becomes key-only. *(Warning: Ensure key auth works before disabling passwords).*
- `SSH_ALLOW_TCP_FORWARDING` (default: `no`): Set to `yes` for bastion use cases.
- `SSH_ALLOW_AGENT_FORWARDING` (default: `no`): Kept `no` by default (agent forwarding is a common escalation vector).

**Firewall:**
- `ALLOW_HTTP` (default: `false`)
- `ALLOW_HTTPS` (default: `false`)

**Unattended Upgrades:**
- `AUTO_REBOOT` (default: `false`): If true, config is modified to allow automatic reboot. *(In production, prefer planned maintenance windows).*

**Example manual override:**
```bash
sudo PROFILE=cloud-web SSH_PORT=2222 AUTO_REBOOT=false make apply
```

---

## 🔄 How it works (Apply Order)

When you run `make apply` (or a profile target), `scripts/apply.sh` performs the following steps deterministically:

1. **Backup snapshot** → Saves current state to `.backups/<timestamp>/`
2. **APT unattended upgrades** → Writes to `/etc/apt/apt.conf.d/`
3. **SSH hardening** → Writes drop-in to `/etc/ssh/sshd_config.d/`, validates with `sshd -t`, and safely restarts SSH.
4. **sysctl baseline** → Writes `/etc/sysctl.d/99-hardening.conf` and applies via `sysctl --system`.
5. **auditd rules** → Writes `/etc/audit/rules.d/` and restarts auditd.
6. **fail2ban jail** → Writes `/etc/fail2ban/jail.d/sshd.local` and restarts fail2ban.
7. **UFW** → Resets, applies baseline rules, and enables logging.
8. **AppArmor** → Checks status (does not modify existing profiles).

---

## 🔍 Audit Mode

Running `sudo make audit` prints a high-signal view of the system state without making any changes:
- Effective SSH configuration (`sshd -T`) for key fields.
- `cloud-init` SSH flags that may override behavior (`ssh_pwauth`, etc.).
- UFW status (verbose).
- Key `sysctl` values used by this baseline.
- `auditd` status + core rules.
- `fail2ban` status for sshd jail.
- `unattended-upgrades` status.
- AppArmor status (if available).

---

## ⏪ Rollback Model

### Backups
`scripts/backup.sh` automatically snapshots key files before any changes into `.backups/<timestamp>/`. Backed up paths include:
- `/etc/ssh/sshd_config` and `sshd_config.d/*`
- `/etc/sysctl.d/99-hardening.conf`
- `/etc/audit/rules.d/99-hardening.rules`
- `/etc/fail2ban/jail.d/sshd.local`
- `/etc/ufw/*` (rules and config files)

### Rollback Execution
`scripts/rollback.sh` restores files from the latest snapshot and safely restarts services (SSH, auditd, fail2ban) and reloads UFW.
> **Tip:** Always keep cloud console access (Serial/OOB) available for emergency recovery if you change SSH connectivity.

---

## 🧪 CI/CD & Linting

**GitHub Actions (`.github/workflows/ci.yml`)** runs on pushes and PRs to enforce an "enterprise signal" of quality discipline:
- **ShellCheck** on all scripts in `scripts/`.
- **shfmt** formatting check.
- **Basic sanity checks** (README, security.md, Makefile).

**Local linting (optional):**
If you have `shellcheck` and `shfmt` installed locally:
```bash
make lint
```

---

## 📜 License
MIT — see `LICENSE` for details.

<br>

<p align="center">
  <b>Developed by Wellington de Freitas</b> | <i>Cloud Security & AI Architect</i>
  <br><br>
  <a href="https://linkedin.com/in/welldefreitas" target="_blank">
    <img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn">
  </a>
  <a href="https://github.com/welldefreitas" target="_blank">
    <img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub">
  </a>
  <a href="https://instagram.com/welldefreitas" target="_blank">
    <img src="https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white" alt="Instagram">
  </a>
</p>
