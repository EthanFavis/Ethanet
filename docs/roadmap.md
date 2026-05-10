# Roadmap

Things I plan to do next, roughly in priority order. This page is a living
document — done items move out, new ideas land at the bottom.

## Near term (next 1–3 months)

### 1. Stand up Proxmox Backup Server

The single biggest gap in the lab. Detailed plan in
[backups.md](backups.md).

- PBS on a dedicated host (likely a newer Pi or a small Tailscale-only VPS;
  the existing Pi 1B doesn't have the resources), tailnet-only
- Daily incremental backup of every CT, encrypted at rest
- `keep-daily=7, keep-weekly=4, keep-monthly=6`
- Quarterly restore drill

### 2. Off-site backup for photos

Immich photos are the only data in the lab that's not recoverable from the
internet. They need an off-site copy.

- `rclone` from `/mnt/data/immich/photos` to an encrypted cloud bucket
- Nightly delta sync, weekly full integrity check
- Restore tested before I declare it "done"

### 3. RAM upgrade

12 GB is the constraining resource. The board has one free SODIMM slot and
supports up to 32 GB.

- Replace the 4 GB stick with another matched 8 GB → **16 GB total**
- Or jump to 2× 16 GB → **32 GB total** (the ceiling for this board)

## Medium term (3–6 months)

### 4. Beszel agents on every LXC

Currently Beszel monitors the Proxmox host. Adding agents inside each
container gives me per-service CPU/memory/disk/network without the host-side
noise.

### 5. Migrate NPM → Caddy + Caddyfile in git

NPM has a friendly UI but its config doesn't live in version control. Caddy
with a `Caddyfile` checked into this repo would be GitOps-friendly and
match where the rest of the lab is heading.

Trade-off: lose the NPM UI's ease of issuing certs ad-hoc — Caddy handles
this automatically, but the UI is gone.

### 6. IaC scaffolding (Terraform + Ansible)

Even on a single Proxmox host, having the lab declared as code is valuable:

- **Terraform / OpenTofu** with the `bpg/proxmox` provider for container
  definitions (CTID, resources, bind mounts, network)
- **Ansible** for in-container config (the *arr stack settings, NPM rules,
  Homepage YAML, Pi-hole config)
- Goal: rebuild the entire lab from this repo on a clean Proxmox install
  in under an hour

This is the most "resume-y" item on the roadmap and probably the highest
work-to-impact ratio for me personally.

## Longer term / wishlist

### 7. Second node + Proxmox cluster

A second mini PC turns the lab into a real cluster: live migration, HA for
critical services, and a place for PBS to live without depending on the Pi.

- Looking for another HP/Lenovo/Dell mini PC second-hand
- Ceph is overkill at this scale; planning to stay on local storage with
  replication for the few HA-needing services

### 8. Disk redundancy for `/mnt/data`

The 1 TB HDD is single-copy. A `mdadm` mirror with a second 1 TB drive
would protect against drive failure. Currently deferred because: media is
re-downloadable, photos will be off-sited (item 2), and the chassis only
has room for one 2.5" drive — would need an external enclosure.

### 9. Tailscale ACLs + tagged services

Right now everything on the tailnet can reach everything else. Proper ACLs
would let me share Jellyfin with friends-on-tailnet without giving them
SSH to every container.

### 10. Documentation polish

- Per-service screenshots for `docs/services/*.md`
- A short blog-style writeup of "why this lab exists and what I learned
  building it" — the resume-conversation starter
- Asciinema recording of a clean PBS restore (proves the backups work)

---

## Stretch / "would be cool"

- A real secrets manager (Vault / SOPS) for any creds that end up in IaC
- Self-hosted Forgejo or Gitea for personal projects (would need to think
  about how to back it up before trusting it)
- Self-hosted password manager (Vaultwarden) — needs a serious backup story
  before I'd put real creds in it
- Replace Pi-hole with AdGuard Home (better UI, native DoH)
- Smart-home integration (Home Assistant) once I have the RAM headroom
