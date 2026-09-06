#!/usr/bin/env bash
set -Eeuo pipefail
. /opt/vps-gaming-optimizer/bin/common.sh
TS="$(date +%Y%m%d-%H%M%S)"
DEST="$backup_root/$TS"
mkdir -p "$DEST"

cp -a /etc/sysctl.d "$DEST/sysctl.d" 2>/dev/null || true
cp -a /etc/systemd/system "$DEST/systemd" 2>/dev/null || true
cp -a /etc/security/limits.d "$DEST/limits.d" 2>/dev/null || true
cp -a /etc/sysctl.conf "$DEST/sysctl.conf" 2>/dev/null || true
cp -a /etc/default/irqbalance "$DEST/irqbalance" 2>/dev/null || true
sysctl -a 2>/dev/null > "$DEST/sysctl-all.txt" || true
ip -details link show > "$DEST/ip-link.txt" 2>&1 || true
ip route show table all > "$DEST/routes.txt" 2>&1 || true
if IFACE="$(first_iface || true)"; then
  tc qdisc show dev "$IFACE" > "$DEST/qdisc.txt" 2>&1 || true
  ethtool "$IFACE" > "$DEST/ethtool.txt" 2>&1 || true
  ethtool -k "$IFACE" > "$DEST/ethtool-offload.txt" 2>&1 || true
fi
printf '%s\n' "$DEST" > /var/lib/vps-gaming-optimizer/latest-backup
log "Backup created: $DEST"
