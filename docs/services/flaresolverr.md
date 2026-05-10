# FlareSolverr (CT 109)

Headless browser proxy that solves Cloudflare anti-bot challenges on behalf
of Prowlarr.

## Container

| | |
|---|---|
| CTID | 109 |
| Hostname | `flaresolverr` |
| OS | Debian 13 |
| Cores | 2 |
| Memory | 2 GB |
| Disk | 4 GB rootfs |
| Tailnet | `flaresolverr` |

## How it's used

Prowlarr is configured with FlareSolverr as a proxy at
`http://flaresolverr:8191`. When an indexer returns a Cloudflare challenge,
Prowlarr forwards the request to FlareSolverr, which spins up a headless
Chromium, solves the challenge, and returns the cleared cookies + body to
Prowlarr.

Memory: 2 GB allocated because Chromium is hungry; idle usage is much lower.

## Upstream

- Source: <https://github.com/FlareSolverr/FlareSolverr>
- Install script: <https://community-scripts.org/scripts/flaresolverr>
