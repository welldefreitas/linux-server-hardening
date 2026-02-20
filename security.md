# Security Model (Threats & Mitigations)

## Goals
- Reduce remote attack surface
- Increase auditability and intrusion detection signals
- Provide safe operational workflow (dry-run, backup, rollback)

## Primary threat scenarios
1. **SSH brute force / credential stuffing**
   - Mitigation: SSH hardening + fail2ban + reduced auth retries

2. **Privilege escalation via misconfig / weak auth**
   - Mitigation: root login disabled; auditd rules for identity/auth changes

3. **Unauthorized configuration tampering**
   - Mitigation: auditd watch rules for sshd_config, sudoers, passwd/group

4. **Service exposure (unexpected open ports)**
   - Mitigation: default-deny firewall + explicit allowlist

5. **Post-compromise stealth**
   - Mitigation: auditd + persistent logs; fail2ban telemetry

## Non-goals
- Application security hardening
- Malware/EDR replacement
- Full CIS certification automation

## Operational risks
- **Lockout risk (SSH)**: mitigated by dry-run, backups, sshd config validation, and explicit flags.
- **Service disruption**: scripts validate configs before restart where possible.
