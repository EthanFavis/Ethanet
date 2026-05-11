# scripts

Operational scripts for the homelab. Each is self-contained — copy to the
target host and run.

## `pve-bootstrap.sh`

Post-install bootstrap for a fresh Proxmox VE host. Bundles the
[community-scripts](https://community-scripts.org) helpers (post-install,
Tailscale-in-LXC, all service installers) with the lab-specific glue
(mounting `/mnt/data`, the standard directory tree, Tailscale on the host).

### What it does

| Step | Action |
|---|---|
| 1 | Preflight — root, on PVE, outbound network reachable |
| 2 | Run `tools/pve/post-pve-install.sh` (no-sub repos, nag removal) |
| 3 | Mount the 1 TB data HDD at `/mnt/data` by UUID; create `jellyfin/`, `immich/`, `downloads/` subtrees. **Refuses to touch any partition that isn't already ext4 — never formats.** |
| 4 | Install Tailscale on the host via the official installer, then `tailscale up` |
| 5 | Iterate `pct list` and offer to run `add-tailscale-lxc.sh` against each container (no-op on a fresh box; useful when re-running) |
| 6 | Interactive menu to install each homelab service (jellyfin, sonarr, radarr, prowlarr, qbittorrent, jellyseerr, flaresolverr, immich, nginxproxymanager, homepage, beszel, crafty-controller) via its community-script |

Every phase prompts before acting, and pauses between scripts so you can
read their output.

### Usage

From the laptop, after a fresh Proxmox install on the host:

```bash
scp scripts/pve-bootstrap.sh root@<pve-ip>:/root/
ssh root@<pve-ip> 'bash /root/pve-bootstrap.sh'
```

Idempotent enough to re-run — skips already-installed Tailscale, already-mounted
`/mnt/data`, etc. Use it again later to push Tailscale into newly-created LXCs.

### What it does *not* do

- Bind mounts from `/mnt/data` into each LXC — those live in
  `/etc/pve/lxc/<CTID>.conf` and are documented in
  [`runbooks/add-lxc.md`](../runbooks/add-lxc.md).
- GPU passthrough config — per-container, see
  [`docs/services/jellyfin.md`](../docs/services/jellyfin.md).
- Tailscale ACLs / MagicDNS — done in the Tailscale admin console.

## `sync-readme-diagram.sh`

Helper for keeping the top-level Mermaid diagram in sync with the README.
