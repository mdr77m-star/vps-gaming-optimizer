#!/usr/bin/env bash
set -Eeuo pipefail
log(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
warn(){ printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die(){ printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
first_iface(){ ip -o route show default 2>/dev/null | awk 'NR==1{print $5; exit}'; }
backup_root=/var/backups/vps-gaming-optimizer
latest_backup(){ ls -1dt "$backup_root"/* 2>/dev/null | head -n1 || true; }
service_exists(){ systemctl list-unit-files --type=service --no-legend 2>/dev/null | awk '{print $1}' | grep -qx "$1"; }
