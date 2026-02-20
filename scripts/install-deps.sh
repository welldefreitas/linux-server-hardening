#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_root

if ! is_debian_like; then
  warn "This installer currently supports Debian/Ubuntu only."
  exit 0
fi

log "Updating apt cache..."
apt-get update -y

log "Installing baseline packages..."
apt-get install -y \
  openssh-server \
  ufw \
  fail2ban \
  auditd \
  audispd-plugins \
  curl \
  ca-certificates

log "Done."
