# Nginx Proxy Manager (CT 101)

The single TLS-terminating ingress for everything in the lab that's exposed to
the public internet. UI at `:81`, HTTP at `:80`, HTTPS at `:443`.

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

| Port | Service | Exposed |
|---:|---|---|
| 80 | nginx (HTTP → redirects to 443) | LAN + public |
| 81 | NPM admin UI (Node) | LAN + tailnet only |
| 443 | nginx (HTTPS, Let's Encrypt) | LAN + public |
| 3000 | node (NPM internal) | LAN |

## Ingress flow

1. DNS for the public domain points to the home WAN IP (Cloudflare proxied).
2. The MikroTik router forwards `:80` and `:443` to `192.168.88.223`.
3. NPM matches `Host:` headers and proxies to the appropriate LXC by hostname
   over the LAN bridge — TLS terminates here, internal hops are plain HTTP.

## Why NPM and not Caddy / Traefik?

NPM has a friendly web UI for issuing Let's Encrypt certs and adding hosts,
which keeps the operational overhead low. Trade-off: less GitOps-friendly than
Caddy (whose Caddyfile lives in version control). I plan to migrate to Caddy
as part of the planned IaC work.

## Upstream

- Project: <https://nginxproxymanager.com/>
- Source: <https://github.com/NginxProxyManager/nginx-proxy-manager>
- Install script: <https://community-scripts.org/scripts/nginxproxymanager>
