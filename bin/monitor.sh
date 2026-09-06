#!/usr/bin/env bash
set -Eeuo pipefail
LOG=/var/log/vps-gaming-optimizer/monitor.log
mkdir -p "$(dirname "$LOG")"
{
  date -Is
  uptime
  IFACE=$(ip -o route show default 2>/dev/null | awk 'NR==1{print $5;exit}')
  echo "iface=$IFACE"
  [[ -n "$IFACE" ]] && tc -s qdisc show dev "$IFACE" 2>/dev/null | sed -n '1,8p' || true
  echo "tcp_cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || true)"
  echo "qdisc=$(sysctl -n net.core.default_qdisc 2>/dev/null || true)"
  echo "conntrack=$(cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo n/a)/$(cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || echo n/a)"
  ss -s 2>/dev/null || true
  echo '---'
} >> "$LOG"
