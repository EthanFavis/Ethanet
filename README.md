# Ethanet — A Single-Node Proxmox Homelab

A small homelab built around three ideas:

- **One small box, many isolated workloads.** A 35 W mini PC runs thirteen
  unprivileged LXC containers — media, photos, game servers, monitoring,
  reverse proxy — without the overhead of full VMs.
- **Tailscale-only access — nothing is publicly exposed.** Every container
  joins my tailnet, and no ports on the router are forwarded to anything in
  the lab. Family and friends who use Jellyfin/Jellyseerr connect through
  Tailscale too. Nginx Proxy Manager isn't a public ingress — it sits
  inside the tailnet and turns LXC IPs into clean HTTPS URLs like
  `jellyfin.ethanet.co.za`, `requests.ethanet.co.za`, and so on. Cloudflare
  hosts authoritative DNS for the domain and provides the API NPM uses for
  Let's Encrypt DNS-01 challenges; it does **not** proxy traffic.
- **Filtered, recursive DNS at the edge.** A 2012 Raspberry Pi runs Pi-hole
  in front of a local Unbound resolver — every DNS query in the house gets
  ad-filtered and resolved from the root servers, never leaking to a public
  upstream.

Built and maintained by **Ethan Favis**. This repo is the documentation for
the lab — kept public as a reference and as a living artifact of what I've
built.

---

## Why this lab exists

I built it to solve three real problems and to learn:

- **A media server** I actually want to use, with quality I control.
- **A way to back up my own data** — particularly photos — without renting
  someone else's cloud.
- **A place to learn** Linux, Proxmox, networking, container internals,
  and reverse proxying by doing the thing rather than reading about it.

Three constraints shaped every decision:

- **Low power.** The whole lab runs on a 35 W TDP mini PC plus a 2012
  Raspberry Pi 1B for DNS. I'd rather work harder on the architecture than
  pay for a rack.
- **Small footprint.** Everything fits on a desk shelf — no rack, no
  closet, no separate room.
- **Low cost.** Corporate-refurb hardware, free open-source software, no
  paid SaaS replacing things I can self-host.

I'm fully invested in growing this lab, but every addition has to keep
clearing those three bars.

---

## At a glance

| | |
|---|---|
| **Host** | HP ProDesk 400 G6 Mini — Intel i5-10500T (6c/12t), 12 GB DDR4, 256 GB NVMe + 1 TB HDD |
| **Hypervisor** | Proxmox VE 9.1.6 (kernel 6.17.13-2-pve) |
| **Workloads** | 13 unprivileged LXC containers (no VMs) |
| **Networking** | UniFi Cloud Gateway Ultra (192.168.88.0/24) → single bridge `vmbr0` → Tailscale on every container |
| **External access** | Tailscale only — no port-forwards. NPM gives services clean HTTPS URLs (Let's Encrypt via Cloudflare DNS-01) |
| **DNS** | [Pi-hole + Unbound](docs/services/pi-hole.md) on a 2012 Raspberry Pi 1B — recursive, ad-filtering |
| **Remote access** | Tailscale (no port-forwards into the LAN) |
| **Monitoring** | Beszel agent on the host + per-container |
| **Backups** | Manual `vzdump` today; PBS planned *(see [docs/backups.md](docs/backups.md))* |
| **Provisioning** | [community-scripts.org](https://community-scripts.org) ProxmoxVE helper scripts |

---

## Topology

```mermaid
flowchart LR
 subgraph Pi["Raspberry Pi"]
        Pihole["Pi‑hole"]
        Unbound["Unbound DNS"]
  end
 subgraph ARR["Arr Stack"]
        Prowlarr["prowlarr (105)"]
        Radarr["radarr (106)"]
        Sonarr["sonarr (107)"]
        QB["qbittorrent (103)"]
  end
 subgraph PVE["Proxmox Host — pve"]
        Homepage["homepage (110)"]
        NPM["nginx proxy manager (101)"]
        Crafty["crafty‑controller (100)"]
        Beszel["beszel (111)"]
        Flare["flaresolverr (109)"]
        ARR
        Seerr["jellyseerr (108)"]
        Jellyfin["jellyfin (104 · GPU)"]
        Immich["immich (102 · GPU)"]
        Storage[("/mnt/data<br>1 TB HDD")]
  end
    Internet(("Internet")) --> Tailnet(("Tailscale<br>tailnet"))
    Pihole --> Unbound
    Prowlarr --> Radarr & Sonarr
    Radarr --> QB & Storage
    Sonarr --> QB & Storage
    Tailnet --> Pihole & NPM
    Flare --> Prowlarr
    Seerr --> Radarr & Sonarr & Jellyfin
    QB --> Storage
    Jellyfin --> Storage
    Immich --> Storage

    %% invisible edges to anchor orphan containers near NPM
    NPM ~~~ Crafty
    NPM ~~~ Homepage
    NPM ~~~ Beszel
    NPM ~~~ Immich

     Internet:::network
     Tailnet:::network
     Pihole:::service
     Unbound:::service
     Homepage:::service
     NPM:::service
     Crafty:::service
     Beszel:::service
     Flare:::service
     Prowlarr:::media
     Radarr:::media
     Sonarr:::media
     QB:::media
     Seerr:::service
     Jellyfin:::service
     Immich:::service
     Storage:::storage
    classDef infra stroke:#818cf8,fill:#eef2ff,color:#000
    classDef service stroke:#2dd4bf,fill:#f0fdfa,color:#000
    classDef storage stroke:#facc15,fill:#fefce8,color:#000
    classDef network stroke:#38bdf8,fill:#f0f9ff,color:#000
    classDef media stroke:#a78bfa,fill:#f5f3ff,color:#000
    style ARR stroke:#AA00FF,fill:transparent
    style PVE fill:transparent
    style Pi fill:transparent
```

*Source: [`diagrams/network.mmd`](diagrams/network.mmd)*

---

## Services

All thirteen containers are unprivileged LXCs with `nesting=1, keyctl=1`,
provisioned through the community-scripts ProxmoxVE helpers. Every container
runs `tailscaled` and is reachable on the tailnet without exposing the LAN.

| CTID | Service | Purpose | Cores | RAM | Disk | Notes |
|------|---------|---------|------:|----:|-----:|-------|
| 100 | [crafty-controller](docs/services/crafty-controller.md) | Minecraft server manager | 4 | 10 GB | 32 GB | Web UI on :8443 |
| 101 | [nginxproxymanager](docs/services/nginxproxymanager.md) | Reverse proxy / TLS | 2 | 2 GB | 8 GB | Tailnet-internal HTTPS |
| 102 | [immich](docs/services/immich.md) | Self-hosted photos | 4 | 6 GB | 20 GB + bind | GPU-accelerated ML |
| 103 | [qbittorrent](docs/services/qbittorrent.md) | BitTorrent client | 2 | 2 GB | 8 GB + bind | Bound to `/downloads` |
| 104 | [jellyfin](docs/services/jellyfin.md) | Media server | 2 | 4 GB | 16 GB + bind | Quick Sync transcode |
| 105 | [prowlarr](docs/services/prowlarr.md) | Indexer manager | 2 | 1 GB | 4 GB | Feeds the *arr stack |
| 106 | [radarr](docs/services/radarr.md) | Movie automation | 2 | 1 GB | 4 GB + bind | |
| 107 | [sonarr](docs/services/sonarr.md) | TV automation | 2 | 1 GB | 4 GB + bind | |
| 108 | [jellyseerr](docs/services/jellyseerr.md) | Request UI | 4 | 4 GB | 12 GB | Front door for users |
| 109 | [flaresolverr](docs/services/flaresolverr.md) | Cloudflare bypass | 2 | 2 GB | 4 GB | For Prowlarr |
| 110 | [homepage](docs/services/homepage.md) | Dashboard | 2 | 4 GB | 6 GB | Landing page |
| 111 | [beszel](docs/services/beszel.md) | Lightweight monitoring | 1 | 512 MB | 5 GB | Hub + agents |
| 112 | [hermes](docs/services/hermes.md) | Hermes AI assistant agent | 2 | 2 GB | 8 GB | Ubuntu 24.04 |

Plus, off-host on a Raspberry Pi 1B:

| Host | Service | Purpose | RAM | Notes |
|------|---------|---------|----:|-------|
| `pihole` | [Pi-hole + Unbound](docs/services/pi-hole.md) | Network-wide ad filtering + recursive DNS | 512 MB | 2012 Raspberry Pi 1B, ARMv6 |

Total committed: **31 vCPU / 39.5 GB RAM** on a 6c/12t / 12 GB host —
oversubscribed on purpose; LXCs share the host kernel and idle very cheaply.

---

## Documentation

- **[docs/hardware.md](docs/hardware.md)** — full hardware inventory and rationale
- **[docs/network.md](docs/network.md)** — LAN, bridges, Tailscale, NPM, DNS
- **[docs/storage.md](docs/storage.md)** — NVMe / HDD layout, LVM-thin, bind mounts
- **[docs/backups.md](docs/backups.md)** — Proxmox Backup Server + retention
- **[docs/roadmap.md](docs/roadmap.md)** — what's next: PBS, off-site photo backup, IaC, clustering, more
- **[docs/services/](docs/services/)** — one page per LXC
- **[runbooks/](runbooks/)** — operational procedures (add LXC, [media stack sync](runbooks/media-sync.md), etc.)
- **[diagrams/](diagrams/)** — Mermaid sources for every diagram in this repo

---

## Design choices worth calling out

**LXC over VMs.** With 12 GB of RAM on the host, a dozen full VMs would be
painful. Unprivileged LXCs share the kernel, start in under a second, and let
me hand a single 1 TB HDD to multiple media services as a bind mount instead of
juggling per-VM virtual disks.

**Tailscale on every container, not just the host.** Each container gets
its own MagicDNS name and tailnet IP, so I can reach any service from my
laptop or phone over WireGuard with zero port-forwards on the LAN. Family
and friends who want Jellyfin/Jellyseerr access join the tailnet — there's
no public ingress to lock down because there isn't one in the first place.

**Hardware-accelerated transcoding into unprivileged containers.** The
`/dev/dri/renderD128` and `/dev/dri/card1` devices are passed into the
`immich` and `jellyfin` containers with the right GID mapping, so Quick Sync
works without dropping container privileges. See
[docs/services/jellyfin.md](docs/services/jellyfin.md) for the full config.

**Reverse proxy for clean HTTPS, not for public ingress.** NPM (101) lives
inside the tailnet and turns each LXC IP into a memorable HTTPS URL —
`jellyfin.ethanet.co.za`, `requests.ethanet.co.za`, etc. Wildcard certs
come from Let's Encrypt using DNS-01 challenges against Cloudflare (which
is authoritative for the domain). The router does **not** forward `:80`
or `:443` to NPM; the only way in from outside is Tailscale.

**Reproducible deploys.** Every container was provisioned via the
[community-scripts ProxmoxVE](https://github.com/community-scripts/ProxmoxVE)
helper scripts. The container IDs and configs in this repo are enough to
recreate the entire lab on a fresh Proxmox host.

---

## URLs

Every service has a clean HTTPS URL on the tailnet. Full table in
[`docs/services/nginxproxymanager.md`](docs/services/nginxproxymanager.md);
the most-used ones are:

- `https://homepage.ethanet.co.za` — landing page
- `https://jellyfin.ethanet.co.za` — media
- `https://immich.ethanet.co.za` — photos
- `https://seerr.ethanet.co.za` — Jellyseerr request portal
- `https://proxmox.ethanet.co.za` — Proxmox VE web UI
- `https://nginx.ethanet.co.za` — NPM admin UI

These resolve to tailnet-private addresses, so they're only reachable from
devices on the tailnet — they're not on the public internet.

---

## The hardware in the wild

![Full front view of the LinkBasic rack, powered on — UniFi Cloud Gateway Ultra, CAT6 patch panel, Netgear GS108 plus the Pi-hole Pi, and the HP ProDesk Mini](photos/ethernet-full-front-on.jpeg)

**This is the entire lab.** Top to bottom in a LinkBasic open-frame rack: the
**UniFi Cloud Gateway Ultra** (its OLED showing live client and throughput
stats), a 12-port CAT6 patch panel, a Netgear GS108 8-port gigabit switch
alongside the 2012 Raspberry Pi running
[Pi-hole + Unbound](docs/services/pi-hole.md), and the HP ProDesk 400 G6 Mini
that hosts thirteen LXC containers under Proxmox.

![Front view with the UniFi gateway OLED lit](photos/ethernet-front-on.jpeg)

![Three-quarter side view of the rack](photos/ethernet-side-off.jpeg)

![Rear view of the rack and cabling](photos/ethernet-back-off.jpeg)

---

## License

Documentation: CC BY 4.0. Configuration snippets: MIT.
