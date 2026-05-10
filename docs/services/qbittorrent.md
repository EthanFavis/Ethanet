# qBittorrent (CT 103)

The download client. Torrents land in `/downloads`; Sonarr and Radarr take it
from there.

## Container

| | |
|---|---|
| CTID | 103 |
| Hostname | `qbittorrent` |
| OS | Debian 13 |
| Cores | 2 |
| Memory | 2 GB |
| Disk | 8 GB rootfs |
| Bind mount | `/mnt/data/downloads` → `/downloads` |
| Tailnet | `qbittorrent` |

## Why `/downloads` is a separate bind, not under `/data`

Sonarr/Radarr need to *see* both `/downloads` and the Jellyfin library at
once, so they get the full `/mnt/data` mount. qBittorrent only writes to
`/downloads`, so it gets a narrower bind mount. Smaller blast radius if
qBittorrent ever gets compromised — it can corrupt downloads but can't
touch the media library.

## Web UI

- `http://qbittorrent:8080` (LAN/tailnet)
- Not exposed publicly. Sonarr/Radarr talk to it over the bridge.

## Upstream

- Project: <https://www.qbittorrent.org/>
- Source: <https://github.com/qbittorrent/qBittorrent>
- Install script: <https://community-scripts.org/scripts/qbittorrent>
