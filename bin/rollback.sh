#!/usr/bin/env bash
set -Eeuo pipefail
. /opt/vps-gaming-optimizer/bin/common.sh
[[ $EUID -eq 0 ]] || die "Run as root."

rm -f /etc/sysctl.d/99-vgo.conf /etc/sysctl.d/99-vgo-capacity.conf
for svc in xray nginx stunnel4 ssh; do
  rm -f "/etc/systemd/system/${svc}.service.d/20-vgo-limits.conf"
  rmdir "/etc/systemd/system/${svc}.service.d" 2>/dev/null || true
done
systemctl daemon-reload
sysctl --system >/dev/null 2>&1 || true

# Best-effort qdisc restoration: let kernel/service defaults apply. We do not guess a prior qdisc.
IFACE="$(first_iface || true)"
[[ -n "$IFACE" ]] && tc qdisc show dev "$IFACE" 2>/dev/null || true

echo "Project overrides removed. No VPN service was restarted."
