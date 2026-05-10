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

- **Tailnet (pretty URL):** `https://seerr.ethanet.co.za` via NPM
- **Tailnet (raw):** `http://seerr:5055`

(Both require being on the tailnet — there's no public ingress.)

## Why it exists

Jellyseerr is the front door for non-technical users. They sign in with their
Jellyfin account, search a library that knows what's already in the
collection, and request what's missing. It's the cleanest UX that doesn't
require teaching them what Sonarr or Prowlarr is.

Family and friends who use Jellyseerr connect via Tailscale — installing
the Tailscale client is a one-time, one-tap thing for them and replaces
the much messier alternative of opening ports on my router.

## Upstream

- Project: <https://docs.jellyseerr.dev/>
- Source: <https://github.com/Fallenbagel/jellyseerr>
- Install script: <https://community-scripts.org/scripts/jellyseerr>
