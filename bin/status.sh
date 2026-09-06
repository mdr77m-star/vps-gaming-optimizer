#!/usr/bin/env bash
set -Eeuo pipefail
. /opt/vps-gaming-optimizer/bin/common.sh

echo '=== VPS Gaming Optimizer status ==='
echo "Date: $(date -Is)"
echo "OS: $(. /etc/os-release; echo "$PRETTY_NAME")"
echo "Kernel: $(uname -r)"
echo "Arch: $(uname -m)"
echo "CPU: $(nproc) vCPU(s)"
echo "RAM: $(free -h | awk '/^Mem:/{print $2}')"
IFACE="$(first_iface || true)"
echo "Default NIC: ${IFACE:-unknown}"
if [[ -n "$IFACE" ]]; then
  ip -br addr show dev "$IFACE" || true
  ip link show dev "$IFACE" | sed -n '1p' || true
  command -v ethtool >/dev/null && ethtool -k "$IFACE" 2>/dev/null | sed -n '1,45p' || true
  tc qdisc show dev "$IFACE" 2>/dev/null || true
fi
printf '\n--- TCP ---\n'
sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || true
sysctl -n net.core.default_qdisc 2>/dev/null || true
printf '\n--- Key sysctls ---\n'
for k in net.ipv4.tcp_fastopen net.ipv4.tcp_ecn net.ipv4.tcp_tw_reuse net.ipv4.tcp_syncookies net.core.netdev_max_backlog net.core.somaxconn net.ipv4.tcp_max_syn_backlog; do
  printf '%-40s %s\n' "$k" "$(sysctl -n "$k" 2>/dev/null || echo unsupported)"
done
printf '\n--- Services ---\n'
for s in xray nginx stunnel4 ssh; do systemctl is-active "$s" 2>/dev/null || true; done
if command -v xray >/dev/null 2>&1; then xray version 2>/dev/null | head -n3 || true; fi
