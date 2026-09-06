#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PREFIX=/opt/vps-gaming-optimizer
REPO_URL="${VGO_REPO_URL:-https://github.com/mdr77m-star/vps-gaming-optimizer.git}"
BRANCH="${VGO_BRANCH:-main}"
TMPDIR=""
cleanup(){ [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"; }
trap cleanup EXIT

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

TMPDIR="$(mktemp -d /tmp/vgo-install.XXXXXX)"
REPO_DIR="$TMPDIR/repo"

# This installer is safe to run via: curl -fsSL .../install.sh | sudo bash
if command -v git >/dev/null 2>&1; then
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1 || {
    echo "Git clone failed; aborting." >&2
    exit 1
  }
else
  apt-get update -y >/dev/null
  apt-get install -y git ca-certificates >/dev/null
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR" >/dev/null 2>&1 || {
    echo "Git clone failed; aborting." >&2
    exit 1
  }
fi

if [[ ! -f "$REPO_DIR/bin/vgo" || ! -f "$REPO_DIR/config/99-vgo.conf" ]]; then
  echo "Repository contents are incomplete; aborting." >&2
  exit 1
fi

mkdir -p "$PREFIX" /var/log/vps-gaming-optimizer /var/lib/vps-gaming-optimizer /var/backups/vps-gaming-optimizer
cp -a "$REPO_DIR"/. "$PREFIX"/
chmod +x "$PREFIX/bin"/* "$PREFIX"/*.sh
ln -sfn "$PREFIX/bin/vgo" /usr/local/bin/vgo

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y iproute2 ethtool procps curl ca-certificates mtr-tiny jq util-linux

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
echo "Profiles: sudo VGO_PROFILE=capacity-60 vgo apply"
