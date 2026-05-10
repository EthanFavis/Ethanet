# Crafty Controller (CT 100)

Web UI for managing one or more Minecraft servers. Friends jump on a server,
I manage it from a browser.

## Container

| | |
|---|---|
| CTID | 100 |
| Hostname | `crafty-controller` |
| OS | Debian 13 |
| Cores | 4 |
| Memory | **10 GB** (the largest container in the lab) |
| Disk | 32 GB rootfs |
| Tailnet | `crafty-controller` |
| LAN IP | 192.168.88.229 (DHCP) |

## How it's reached

- **Web UI:** `https://crafty-controller:8443`
- **Game ports:** Minecraft default `:25565` (and others Crafty assigns per
  server) — exposed on the LAN; for friends outside the LAN, they connect
  via Tailscale.

## Why so much RAM?

This container hosts the JVM heap for the actual Minecraft server(s) — not
just the management UI. 10 GB is generous: a vanilla server runs happily in
~4 GB, but modded packs need the headroom.

## Upstream

- Project: <https://craftycontrol.com/>
- Source: <https://gitlab.com/crafty-controller/crafty-4>
- Install script: <https://community-scripts.org/scripts/crafty-controller>
