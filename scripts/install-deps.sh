#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_root

if ! is_debian_like; then
  warn "This installer currently supports Debian/Ubuntu only."
  exit 0
fi

# Identify distro (Ubuntu cloud target)
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  log "Detected OS: ${NAME:-unknown} ${VERSION_ID:-unknown}"
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
  unattended-upgrades \
  apt-listchanges \
  apparmor \
  apparmor-utils \
  curl \
  ca-certificates

log "Done."
