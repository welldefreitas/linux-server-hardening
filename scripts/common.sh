#!/usr/bin/env bash
set -euo pipefail

# Common helpers used across scripts.
# Intentionally verbose and defensive to reduce operational mistakes.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# BACKUP_DIR is consumed by other scripts that source this file.
# shellcheck disable=SC2034
export BACKUP_DIR="${ROOT_DIR}/.backups"

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
err()  { echo "[ERROR] $*" >&2; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "This action must be run as root (use sudo)."
    exit 1
  fi
}

is_debian_like() {
  [[ -f /etc/debian_version ]]
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

ensure_dir() {
  mkdir -p "$1"
}

timestamp() {
  date +"%Y%m%d-%H%M%S"
}

backup_file() {
  local src="$1"
  local dst_dir="$2"
  if [[ -f "$src" ]]; then
    ensure_dir "$dst_dir"
    cp -a "$src" "$dst_dir/"
    log "Backed up: $src -> $dst_dir/"
  else
    warn "File not found (skip backup): $src"
  fi
}

write_file_if_changed() {
  local src_template="$1"
  local dst="$2"

  if [[ ! -f "$src_template" ]]; then
    err "Template not found: $src_template"
    exit 1
  fi

  if [[ -f "$dst" ]] && cmp -s "$src_template" "$dst"; then
    log "No change: $dst"
    return 0
  fi

  cp -a "$src_template" "$dst"
  log "Updated: $dst"
}

restart_service_safe() {
  local svc="$1"
  if systemctl is-enabled "$svc" >/dev/null 2>&1 || systemctl status "$svc" >/dev/null 2>&1; then
    systemctl restart "$svc"
    log "Restarted service: $svc"
  else
    warn "Service not found/enabled (skip): $svc"
  fi
}
