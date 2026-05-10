# Nginx Proxy Manager (CT 101)

The TLS terminator and pretty-URL provider for the lab. **NPM is not a
public ingress** — the router doesn't forward any ports to it. It exists
so I can type `https://jellyfin.ethanet.co.za` from inside the tailnet
instead of remembering that Jellyfin lives at `192.168.88.x:8096`.

## Container

| | |
|---|---|
| CTID | 101 |
| Hostname | `nginxproxymanager` |
| OS | Debian 12 (bookworm) |
| Cores | 2 |
| Memory | 2 GB |
| Disk | 8 GB rootfs |
| Tailnet | `nginxproxymanager` |
| LAN IP | 192.168.88.223 (DHCP) |

## Listening ports (from `ss -tlnp`)

| Port | Service | Reachable from |
|---:|---|---|
| 80 | nginx (HTTP → redirects to 443) | LAN + tailnet |
| 81 | NPM admin UI (Node) | LAN + tailnet |
| 443 | nginx (HTTPS, Let's Encrypt) | LAN + tailnet |
| 3000 | node (NPM internal) | LAN |

None of these ports are forwarded by the router. From outside the LAN,
they're only reachable over Tailscale.

## Request flow

1. A client on the tailnet (or LAN) opens `https://jellyfin.ethanet.co.za`.
2. Cloudflare DNS resolves that subdomain to NPM's address (tailnet-private
   or LAN — either way, only routable to peers on those networks).
3. NPM terminates TLS using its `*.ethanet.co.za` cert and proxies the
   request by `Host:` header to the matching upstream over Tailscale (NPM
   uses each LXC's tailnet IP as the upstream — see the table below).

## The proxy hosts

Each subdomain points to a service inside the tailnet. NPM uses the
container's tailnet IP as the upstream — Tailscale handles the transport,
which keeps the routing identical whether NPM and the upstream are on the
same host or not.

| Subdomain (`*.ethanet.co.za`) | Upstream | Service |
|---|---|---|
| `beszel` | `http://100.92.160.37:8090` | Beszel monitoring |
| `crafty` | `https://100.72.24.107:8443` | Crafty Controller (Minecraft) |
| `flare` | `http://100.70.250.101:8191` | FlareSolverr |
| `homepage` | `http://100.64.39.94:3000` | Homepage dashboard |
| `immich` | `http://100.120.47.3:2283` | Immich |
| `jellyfin` | `http://100.75.208.39:8096` | Jellyfin |
| `nginx` | `http://100.100.15.28:81` | NPM admin UI |
| `prowlarr` | `http://100.108.232.30:9696` | Prowlarr |
| `proxmox` | `https://100.95.82.120:8006` | Proxmox VE web UI |
| `qbit` | `http://100.64.182.51:8090` | qBittorrent |
| `radarr` | `http://100.78.8.89:7878` | Radarr |
| `seerr` | `http://100.84.237.73:5055` | Jellyseerr |
| `sonarr` | `http://100.90.176.28:8989` | Sonarr |

All of these get a Let's Encrypt cert via the wildcard
`*.ethanet.co.za` issuance flow described below. None of them are
reachable from the public internet.

## Cert issuance — DNS-01 against Cloudflare

NPM holds a Cloudflare API token scoped to `ethanet.co.za`. When a cert
is up for renewal, NPM:

1. Asks Let's Encrypt for a challenge.
2. Uses the Cloudflare API to write the required `_acme-challenge` TXT
   record on the zone.
3. Tells Let's Encrypt to verify, then deletes the TXT record.

This means **no inbound HTTP-01 traffic from the public internet is ever
required** — ideal for a lab that doesn't expose `:80` to the world.

## Why NPM and not Caddy / Traefik?

NPM has a friendly web UI for issuing Let's Encrypt certs and adding hosts,
which keeps the operational overhead low. Trade-off: less GitOps-friendly than
Caddy (whose Caddyfile lives in version control). I plan to migrate to Caddy
as part of the planned IaC work.

## Upstream

- Project: <https://nginxproxymanager.com/>
- Source: <https://github.com/NginxProxyManager/nginx-proxy-manager>
- Install script: <https://community-scripts.org/scripts/nginxproxymanager>
