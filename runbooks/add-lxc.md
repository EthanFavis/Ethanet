# Runbook: Add a new LXC

Most new services in this lab are deployed via the [community-scripts.org
ProxmoxVE helpers](https://community-scripts.org). The flow is:

1. **Pick a script.** Browse https://community-scripts.org/scripts and copy
   the `bash -c "$(curl ...)"` one-liner for the service.
2. **Run it on the host as root.** From the Proxmox UI shell or via SSH to
   `pve`.
3. **Choose advanced options** when prompted:
   - **CTID:** next free in the 100–199 range
   - **Hostname:** match the service name (used as the Tailscale MagicDNS name)
   - **Cores / RAM / disk:** see the table in the README for sizing precedent
   - **Storage:** `local-lvm`
   - **Bridge:** `vmbr0`
   - **IP config:** DHCP (the MikroTik handles leases)
   - **Unprivileged:** yes
   - **Features:** `nesting=1, keyctl=1` (the default for these scripts)
4. **Add Tailscale.** The community scripts have a "Tailscale" post-install
   helper — run it after the container is up:
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/tools/addon/add-tailscale-lxc.sh)"
   ```
5. **Bind mounts** (if needed) — edit `/etc/pve/lxc/<CTID>.conf` and add e.g.
   ```
   mp0: /mnt/data/<service>/config,mp=/config
   ```
   then `pct restart <CTID>`.
6. **GPU passthrough** (if needed) — see
   [services/jellyfin.md](../docs/services/jellyfin.md) for the `dev0`/`dev1`
   pattern and matching GIDs.
7. **Document it.** Add a `docs/services/<name>.md` page following the
   [`_template.md`](../docs/services/_template.md) shape, and link it from
   the README service table.
8. **Add to NPM** if it should be public-facing.
