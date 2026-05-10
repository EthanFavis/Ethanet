# Sonarr (CT 107)

The TV side of the *arr stack. Watches Prowlarr-fed indexers for new episodes,
sends them to qBittorrent, and hardlinks finished downloads into the Jellyfin
library.

## Container

| | |
|---|---|
| CTID | 107 |
| Hostname | `sonarr` |
| OS | Debian 13 |
| Cores | 2 |
| Memory | 1 GB |
| Disk | 4 GB rootfs |
| Bind mount | `/mnt/data` → `/data` (full HDD) |
| Tailnet | `sonarr` |

## Why the full `/mnt/data` is mounted

Sonarr needs to see both `downloads/` and `jellyfin/media/` to perform
**hardlink** moves — that's how a finished torrent ends up in the Jellyfin
library without doubling the disk usage. If the two paths were on different
filesystems (or in separate bind mounts that crossed mount boundaries inside
the container), Sonarr would fall back to copy-then-delete and use 2× disk
during the transfer.

## Configuration anchors

- **Root folder:** `/data/jellyfin/media/TV`
- **Download client:** qBittorrent at `http://qbittorrent:8080` (over the
  bridge — the *arr containers don't need Tailscale for this hop)
- **Indexers:** managed centrally by Prowlarr (CT 105) — sync via
  Settings → Apps in Prowlarr
- **Connect:** Jellyseerr posts requests, Jellyfin gets a "Library updated"
  webhook

## Upstream

- Project: <https://sonarr.tv/>
- Source: <https://github.com/Sonarr/Sonarr>
- Install script: <https://community-scripts.org/scripts/sonarr>
