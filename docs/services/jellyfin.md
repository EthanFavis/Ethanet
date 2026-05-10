# Jellyfin (CT 104)

The media server. The whole *arr stack and qBittorrent exist to feed this
container's `/media` directory.

## Container

| | |
|---|---|
| CTID | 104 |
| Hostname | `jellyfin` |
| OS | Ubuntu (LXC template — the only non-Debian container in the lab) |
| Cores | 2 |
| Memory | 4 GB |
| Disk | 16 GB rootfs + bind mounts |
| Bind mounts | `/mnt/data/jellyfin/media` → `/media`, `/mnt/data/jellyfin/config` → `/config` |
| Devices | `/dev/dri/renderD128` (gid=993), `/dev/dri/card1` (gid=44) |
| Tailnet | `jellyfin` |
| Privileged | no — `unprivileged: 1`, `nesting=1, keyctl=1` |

## Hardware-accelerated transcoding

The `dev0` and `dev1` lines in `/etc/pve/lxc/104.conf` pass the host's Intel
UHD 630 render and card nodes into the container with the GIDs that match
Jellyfin's user inside the container. No privilege escalation required —
this is the cleanest part of the lab and the part I'm most pleased with.

To verify the VAAPI driver is loaded inside the container:

```bash
pct exec 104 -- vainfo
```

Look for `iHD` (the Intel media driver) and the supported `VAProfile*`
entries — H264, HEVC, VP9 should all be listed.

In Jellyfin's admin UI:

> Dashboard → Playback → Hardware acceleration: **Intel QuickSync (QSV)**
> Enable hardware decoding for: H.264, HEVC, VP9
> Enable tone mapping, low-power encoding.

(UHD 630 / Comet Lake doesn't have AV1 hardware decode — that landed with
Tiger Lake / 11th gen. AV1 streams will fall back to software.)

## How it's reached

- **Tailnet (pretty URL):** `https://jellyfin.ethanet.co.za` via NPM
- **LAN/Tailnet (raw):** `http://jellyfin:8096` or the DHCP-assigned LAN IP

(All access is gated by Tailscale — there's no public ingress.)

## Notes

- The container is Ubuntu rather than Debian because the upstream community
  script defaults to Ubuntu for Jellyfin (Intel media driver packaging is
  more current).
- All Jellyfin metadata lives on `/config` on the HDD — survives a container
  rebuild without re-scraping the library.

## Upstream

- Project: <https://jellyfin.org/>
- Source: <https://github.com/jellyfin/jellyfin>
- Install script: <https://community-scripts.org/scripts/jellyfin>
