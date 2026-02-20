#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_root

log "Auditing system hardening state (no changes)."

# SSH effective config
if has_cmd sshd; then
  log "SSH: checking effective configuration..."
  sshd -T 2>/dev/null | egrep -i "port|permitrootlogin|passwordauthentication|maxauthtries|logingracetime|clientaliveinterval|clientalivecountmax|pubkeyauthentication" || true
else
  warn "sshd not found; skipping SSH audit."
fi

# Firewall
if has_cmd ufw; then
  log "UFW status:"
  ufw status verbose || true
else
  warn "ufw not installed."
fi

# sysctl key checks
log "sysctl key checks:"
sysctl net.ipv4.conf.all.rp_filter 2>/dev/null || true
sysctl net.ipv4.conf.default.rp_filter 2>/dev/null || true
sysctl net.ipv4.tcp_syncookies 2>/dev/null || true
sysctl net.ipv4.conf.all.accept_redirects 2>/dev/null || true
sysctl net.ipv4.conf.all.send_redirects 2>/dev/null || true

# auditd
log "auditd status:"
systemctl is-active auditd >/dev/null 2>&1 && log "auditd: active" || warn "auditd: not active"
if has_cmd auditctl; then
  auditctl -l | head -n 50 || true
fi

# fail2ban
log "fail2ban status:"
systemctl is-active fail2ban >/dev/null 2>&1 && log "fail2ban: active" || warn "fail2ban: not active"
if has_cmd fail2ban-client; then
  fail2ban-client status sshd 2>/dev/null || true
fi

log "Audit completed."
