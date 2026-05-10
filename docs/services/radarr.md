# Radarr (CT 106)

The movies counterpart to [Sonarr](sonarr.md). Same shape, same patterns —
just for films instead of TV.

## Container

| | |
|---|---|
| CTID | 106 |
| Hostname | `radarr` |
| OS | Debian 13 |
| Cores | 2 |
| Memory | 1 GB |
| Disk | 4 GB rootfs |
| Bind mount | `/mnt/data` → `/data` (full HDD, same reason as Sonarr) |
| Tailnet | `radarr` |

## Configuration anchors

- **Root folder:** `/data/jellyfin/media/Movies`
- **Download client:** qBittorrent at `http://qbittorrent:8080`
- **Indexers:** managed by Prowlarr (CT 105)
- **Quality profile:** 1080p preferred, 4K fallback for native UHD releases

## Upstream

- Project: <https://radarr.video/>
- Source: <https://github.com/Radarr/Radarr>
- Install script: <https://community-scripts.org/scripts/radarr>
