# Immich (CT 102)

Self-hosted Google Photos replacement. Phone uploads photos via the Immich
mobile app, the container does face recognition / object detection / smart
search, and the photos sit on `/mnt/data` — never leaving the lab.

## Container

| | |
|---|---|
| CTID | 102 |
| Hostname | `immich` |
| OS | Debian 13 (trixie) |
| Cores | 4 |
| Memory | 6 GB |
| Disk | 20 GB rootfs + bind mounts |
| Bind mounts | `/mnt/data/immich/photos` → `/photos`, `/mnt/data/immich/config` → `/config` |
| Devices | `/dev/dri/renderD128` (gid=992), `/dev/dri/card1` (gid=44) |
| Tailnet | `immich` |
| LAN IP | 192.168.88.184 (DHCP) |

## What runs inside

The community-script Immich install is "all-in-one" inside the container, so
unlike the official Docker compose deployment everything is local services:

- `immich-web.service` — API + web UI
- `immich-ml.service` — ML inference (CLIP, face recognition)
- `postgresql@16-main.service` — Postgres on `127.0.0.1:5432`
- `redis-server.service` — Redis on `127.0.0.1:6379`
- `python ... :3003` — the ML server

The GPU is passed in for the ML service to accelerate CLIP embeddings and
face detection on bulk imports.

## How it's reached

- **Tailnet (pretty URL):** `https://photos.ethanet.co.za` via NPM
- **Tailnet (raw):** `http://immich:2283`

## Notes

- Photos live on the slow HDD (`/mnt/data/immich/photos`) — that's fine for
  storage but uploads from the phone are bottlenecked by HDD random write,
  not network.
- Postgres + Redis are in-container, so the PBS container backup captures
  the entire DB along with the metadata. The actual JPEGs/HEICs on the
  bind-mounted volume need their own backup story.

## Upstream

- Project: <https://immich.app/>
- Source: <https://github.com/immich-app/immich>
- Install script: <https://community-scripts.org/scripts/immich>
