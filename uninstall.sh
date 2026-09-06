#!/usr/bin/env bash
set -Eeuo pipefail
if [[ $EUID -ne 0 ]]; then echo "Run as root." >&2; exit 1; fi
systemctl disable --now vgo-monitor.timer 2>/dev/null || true
rm -f /etc/systemd/system/vgo-monitor.timer /etc/systemd/system/vgo-monitor.service
systemctl daemon-reload
rm -f /usr/local/bin/vgo
rm -f /etc/sysctl.d/99-vgo.conf /etc/sysctl.d/99-vgo-capacity.conf
for svc in xray nginx stunnel4 ssh; do
  rm -f "/etc/systemd/system/${svc}.service.d/20-vgo-limits.conf"
  rmdir "/etc/systemd/system/${svc}.service.d" 2>/dev/null || true
done
systemctl daemon-reload
sysctl --system >/dev/null 2>&1 || true
if [[ -d /opt/vps-gaming-optimizer ]]; then
  rm -rf /opt/vps-gaming-optimizer
fi
rm -rf /var/lib/vps-gaming-optimizer /var/log/vps-gaming-optimizer
# Service drop-ins created by this project are removed only by rollback.sh so users can inspect backups first.
echo "Project removed. Backups under /var/backups/vps-gaming-optimizer were preserved."
