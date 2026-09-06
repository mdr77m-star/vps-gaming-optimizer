#!/usr/bin/env bash
set -Eeuo pipefail
. /opt/vps-gaming-optimizer/bin/common.sh
TARGET="${1:-1.1.1.1}"
command -v ping >/dev/null 2>&1 || die "ping is required"
echo "Probing IPv4 PMTU to $TARGET. This does NOT change interface MTU."
for S in 1472 1464 1452 1440 1420 1400 1380 1360 1340 1320 1300 1280; do
  if ping -4 -M do -c 2 -W 2 -s "$S" "$TARGET" >/tmp/vgo-pmtu.$$ 2>&1; then
    echo "PASS payload=$S total_ipv4=$((S+28))"
    break
  else
    echo "FAIL payload=$S total_ipv4=$((S+28))"
  fi
done
rm -f /tmp/vgo-pmtu.$$
