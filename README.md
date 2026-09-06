# VPS Gaming & VPN Optimizer

Production-oriented network/system tuning for Ubuntu VPS hosts running VPN/proxy workloads (Xray, Nginx, SSH, Stunnel, WireGuard, etc.). Designed to improve **latency under load, connection stability, socket capacity, and service resilience** without pretending to change the physical Internet route.

## What it does

- Detects CPU, RAM, architecture, NIC, MTU, qdisc, congestion control and common VPN services.
- Applies a conservative low-latency TCP profile with BBR when available and FQ by default.
- Tunes socket/backlog/conntrack limits for multi-user VPN workloads.
- Raises service `LimitNOFILE` through systemd drop-ins for Xray/Nginx/Stunnel/SSH when those services exist.
- Enables safe TCP Fast Open and keepalive settings where the kernel supports them.
- Avoids destructive “magic tweaks”: no Lotserver/custom kernel, no arbitrary MTU changes, no blind CAKE shaping, no disabling GRO/TSO.
- Creates a full timestamped backup and supports rollback.
- Includes benchmarking and route/PMTU diagnostics.
- Includes an optional Xray socket-options snippet instead of silently rewriting a live Xray JSON configuration.

## Important

This project cannot reduce the physical Morocco↔Germany propagation delay. It is optimized for **latency under traffic, jitter, connection setup, packet queueing, and service capacity**. Route quality should be measured with MTR and real game endpoints.

## Compatibility

Tested design target: Ubuntu 22.04/24.04, x86_64 and ARM64/aarch64. It should fail safely on unsupported systems rather than forcing incompatible kernel parameters.

## Quick install from GitHub

After uploading this repository to your GitHub account:

```bash
curl -fsSL https://raw.githubusercontent.com/mdr77m-star/vps-gaming-optimizer/main/install.sh | sudo bash
```

Replace `USER/REPO` with your repository path. For maximum trust, clone the repository and run the script locally instead of piping it to shell.

## Commands

```bash
sudo /opt/vps-gaming-optimizer/bin/vgo status
sudo /opt/vps-gaming-optimizer/bin/vgo backup
sudo /opt/vps-gaming-optimizer/bin/vgo apply
sudo /opt/vps-gaming-optimizer/bin/vgo benchmark
sudo /opt/vps-gaming-optimizer/bin/vgo mtr <target>
sudo /opt/vps-gaming-optimizer/bin/vgo pmtu <target>
sudo /opt/vps-gaming-optimizer/bin/vgo rollback
```

The default profile is `safe-low-latency`.

## Profiles

`safe-low-latency` (default): BBR + FQ when available, larger but bounded TCP buffers, high connection backlog, TFO, sensible keepalive, NOFILE limits, and safe kernel settings.

`capacity-60`: same network profile plus more aggressive file descriptor/service limits intended for a small VPN server with dozens of concurrent users. It does not increase CPU/RAM or bandwidth limits imposed by the cloud provider.

`cake-manual`: template only. CAKE is not automatically enabled because shaping requires the actual bottleneck rate; wrong shaping can reduce throughput.

## Xray

The repository does not automatically rewrite `/etc/xray/config.json`. It provides `config/xray-sockopt-snippet.json` showing optional settings for Xray versions that support them. Validate your installed Xray version and configuration schema before merging any snippet.

Your older Xray 1.6.x installation should be treated separately from the host tuning. The project can detect it, but it does not perform a blind in-place Xray upgrade.

## Security

- Does not disable the firewall.
- Does not open new public ports.
- Does not weaken SSH authentication.
- Does not enable TCP spoofing or reverse-path tricks.
- Does not install third-party kernels.
- Backups are stored under `/var/backups/vps-gaming-optimizer/<timestamp>/`.

## Uninstall

```bash
sudo /opt/vps-gaming-optimizer/uninstall.sh
```

Uninstall removes the project's files and systemd drop-ins, but it does not automatically delete backup history.
