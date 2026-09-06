#!/usr/bin/env bash
set -Eeuo pipefail
. /opt/vps-gaming-optimizer/bin/common.sh
TARGET="${1:-}"
[[ -n "$TARGET" ]] || die "Usage: vgo mtr TARGET"
command -v mtr >/dev/null 2>&1 || die "mtr-tiny is not installed"
echo "=== IPv4 MTR: $TARGET ==="
mtr -4 -rwzc 50 "$TARGET"
