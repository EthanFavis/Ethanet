# Jellyseerr (CT 108)

The user-facing request portal. Family and friends search for shows and
movies here; Jellyseerr turns approvals into Sonarr/Radarr API calls.

## Container

| | |
|---|---|
| CTID | 108 |
| Hostname | `seerr` (the LXC name) |
| OS | Debian 13 |
| Cores | 4 |
| Memory | 4 GB |
| Disk | 12 GB rootfs |
| Tailnet | `seerr` |

> Note: the LXC is named `seerr` for short, but the application is
> **Jellyseerr** (the Jellyfin-targeted fork of Overseerr).

## How it's reached

- **Public:** `https://requests.<my-domain>` via NPM → Cloudflare
- **Tailnet:** `http://seerr:5055`

## Why this is the only public-facing app besides Jellyfin

Jellyseerr is the front door for non-technical users. They sign in with their
Jellyfin account, search a library that knows what's already in the
collection, and request what's missing. It's the cleanest UX that doesn't
require teaching them what Sonarr or Prowlarr is.

## Upstream

- Project: <https://docs.jellyseerr.dev/>
- Source: <https://github.com/Fallenbagel/jellyseerr>
- Install script: <https://community-scripts.org/scripts/jellyseerr>
