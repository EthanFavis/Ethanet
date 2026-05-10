# Beszel (CT 111)

Lightweight server monitoring — like a stripped-down Grafana that's actually
fun to look at. Hub container plus an agent on each monitored host.

## Container

| | |
|---|---|
| CTID | 111 |
| Hostname | `beszel` |
| OS | Debian 13 |
| Cores | 1 |
| Memory | 512 MB |
| Disk | 5 GB rootfs |
| Tailnet | `beszel` |

## What it monitors

- The Proxmox host (CPU / memory / disk / network / temps)
- Each LXC, optionally, via the Beszel agent
- The `pihole` Raspberry Pi and any other tailnet host I add later

The hub talks to each agent over SSH (Beszel's native transport). With
every container on the tailnet, the hub-to-agent hops ride Tailscale —
nothing about Beszel is exposed to the public internet.

## Why Beszel and not Prometheus + Grafana?

For a single host, Prometheus + Grafana is overkill. Beszel gives me 80 % of
what I'd actually look at, with one container instead of three, and no PromQL
to remember. If I outgrow it I'll graduate to the full stack.

## Upstream

- Project: <https://beszel.dev/>
- Source: <https://github.com/henrygd/beszel>
- Install script: <https://community-scripts.org/scripts/beszel>
