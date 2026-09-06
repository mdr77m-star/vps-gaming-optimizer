#!/usr/bin/env bash
set -Eeuo pipefail
. /opt/vps-gaming-optimizer/bin/common.sh

echo "timestamp=$(date -Is)"
echo "kernel=$(uname -r)"
echo "arch=$(uname -m)"
echo "cpu=$(nproc)"
echo "memory=$(free -m | awk '/^Mem:/{print $2}')MiB"
IFACE="$(first_iface || true)"
echo "iface=${IFACE:-none}"
if [[ -n "$IFACE" ]]; then
  echo "mtu=$(ip link show dev "$IFACE" | sed -n '1s/.*mtu \([0-9]*\).*/\1/p')"
  echo "qdisc=$(tc qdisc show dev "$IFACE" 2>/dev/null | head -n1)"
fi
for k in net.ipv4.tcp_congestion_control net.core.default_qdisc net.core.netdev_max_backlog net.core.somaxconn net.ipv4.tcp_max_syn_backlog net.ipv4.tcp_fastopen net.ipv4.tcp_mtu_probing net.ipv4.tcp_notsent_lowat; do
  echo "$k=$(sysctl -n "$k" 2>/dev/null || echo unsupported)"
done
printf '\n--- load ---\n'
uptime
printf '\n--- memory ---\n'; free -h
printf '\n--- sockets ---\n'; ss -s || true
printf '\n--- TCP retransmissions ---\n'; nstat -az 2>/dev/null | grep -E 'Tcp(RetransSegs|ExtTCPTimeouts|InErrs|OutSegs)' || true
printf '\n--- conntrack ---\n'
if [[ -r /proc/sys/net/netfilter/nf_conntrack_max ]]; then
  echo "max=$(cat /proc/sys/net/netfilter/nf_conntrack_max)"
  if [[ -r /proc/sys/net/netfilter/nf_conntrack_count ]]; then echo "count=$(cat /proc/sys/net/netfilter/nf_conntrack_count)"; fi
fi
printf '\n--- services ---\n'
for s in xray nginx stunnel4 ssh; do
  if systemctl cat "$s" >/dev/null 2>&1; then echo "$s=$(systemctl is-active "$s" 2>/dev/null || true)"; fi
done
