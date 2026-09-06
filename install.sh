#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PREFIX=/opt/vps-gaming-optimizer
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash install.sh" >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot detect OS." >&2
  exit 1
fi
. /etc/os-release
case "${ID:-}" in
  ubuntu) ;;
  *) echo "Supported target: Ubuntu. Detected: ${ID:-unknown}" >&2; exit 1;;
esac

mkdir -p "$PREFIX" /var/log/vps-gaming-optimizer /var/lib/vps-gaming-optimizer /var/backups/vps-gaming-optimizer
cp -a "$REPO_DIR"/. "$PREFIX"/
chmod +x "$PREFIX"/bin/* "$PREFIX"/*.sh

ln -sfn "$PREFIX/bin/vgo" /usr/local/bin/vgo

if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y iproute2 ethtool procps curl ca-certificates mtr-tiny jq util-linux
fi

cat > /etc/systemd/system/vgo-monitor.service <<UNIT
[Unit]
Description=VPS Gaming Optimizer health snapshot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/vps-gaming-optimizer/bin/monitor.sh
UNIT

cat > /etc/systemd/system/vgo-monitor.timer <<UNIT
[Unit]
Description=Hourly VPS Gaming Optimizer health snapshot

[Timer]
OnBootSec=10min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now vgo-monitor.timer

"$PREFIX/bin/vgo" status

echo
 echo "Installed. Run: sudo vgo apply"
