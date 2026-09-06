#!/usr/bin/env bash
set -Eeuo pipefail
. /opt/vps-gaming-optimizer/bin/common.sh
BASE=/opt/vps-gaming-optimizer

PROFILE="${VGO_PROFILE:-safe-low-latency}"
[[ $EUID -eq 0 ]] || die "Run as root."

log "Starting profile: $PROFILE"
"$BASE/bin/benchmark.sh" > /var/log/vps-gaming-optimizer/before-apply-$(date +%Y%m%d-%H%M%S).log 2>&1 || true
"$BASE/bin/backup.sh"

# Only manage our own file. Do not rewrite /etc/sysctl.conf or third-party files.
install -m 0644 "$BASE/config/99-vgo.conf" /etc/sysctl.d/99-vgo.conf

if [[ "$PROFILE" == "capacity-60" ]]; then
  cat > /etc/sysctl.d/99-vgo-capacity.conf <<'CONF'
net.core.somaxconn = 131072
net.ipv4.tcp_max_syn_backlog = 32768
net.core.netdev_max_backlog = 32768
net.netfilter.nf_conntrack_max = 262144
CONF
else
  rm -f /etc/sysctl.d/99-vgo-capacity.conf
fi

# Apply only our files. Invalid keys are warned but do not abort the whole install.
sysctl --load=/etc/sysctl.d/99-vgo.conf || true
[[ -f /etc/sysctl.d/99-vgo-capacity.conf ]] && sysctl --load=/etc/sysctl.d/99-vgo-capacity.conf || true

# Service resource limits: safe for high connection counts.
for svc in xray nginx stunnel4 ssh; do
  if systemctl cat "$svc" >/dev/null 2>&1; then
    mkdir -p "/etc/systemd/system/${svc}.service.d"
    cat > "/etc/systemd/system/${svc}.service.d/20-vgo-limits.conf" <<'UNIT'
[Service]
LimitNOFILE=1048576
TasksMax=infinity
UNIT
  fi
done
systemctl daemon-reload

# Do not force CPU governor or RPS on single-queue cloud NICs. Just report capability.
IFACE="$(first_iface || true)"
if [[ -n "$IFACE" ]]; then
  log "NIC: $IFACE"
  if command -v ethtool >/dev/null 2>&1; then
    ethtool -l "$IFACE" 2>/dev/null | sed -n '1,35p' || true
    ethtool -c "$IFACE" 2>/dev/null | sed -n '1,40p' || true
  fi
  tc qdisc show dev "$IFACE" 2>/dev/null || true
fi

# Restart nothing. Reloading sysctl and systemd drop-ins is enough; existing sockets keep working.
"$BASE/bin/status.sh"
"$BASE/bin/benchmark.sh" > /var/log/vps-gaming-optimizer/after-apply-$(date +%Y%m%d-%H%M%S).log 2>&1 || true
log "Profile applied. A reboot is NOT required for sysctl values; existing VPN connections are not intentionally restarted."
