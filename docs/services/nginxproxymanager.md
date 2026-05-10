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
3. NPM terminates TLS using its wildcard `*.ethanet.co.za` cert and
   proxies the request by `Host:` header to the matching LXC in plain HTTP
   over the bridge.

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
