# Architecture and design decisions

## Why FQ instead of blindly switching to CAKE

FQ works without a configured bottleneck rate and pairs naturally with BBR on a server. CAKE is useful when you can shape the actual bottleneck, but choosing an arbitrary shaping rate on a cloud VPS can reduce capacity. The project therefore leaves CAKE manual.

## Why no custom kernel

Custom “gaming kernels” can break provider modules, cloud drivers, boot behavior, DKMS and recovery. The supported Ubuntu kernel already exposes the tunables needed for this class of optimization.

## Why no blind MTU change

OCI may expose a 9000-byte interface MTU while the end-to-end path through a VPN, ISP, or tunnel can have a much smaller PMTU. The project probes PMTU but never changes MTU automatically.

## Why no global RPS/RFS forcing

A single-queue virtio NIC cannot create additional hardware queues by setting RPS. Artificially moving packets between CPUs can add overhead on small 2-vCPU instances. The optimizer reports the queue layout rather than forcing a generic policy.

## 60-user workload

The `capacity-60` profile raises bounded queues/conntrack/NOFILE limits but remains CPU- and memory-aware. Sixty VPN subscribers do not inherently require huge buffers; throughput, connection churn, cipher/transport mix, and concurrent flows matter more than user count alone.
