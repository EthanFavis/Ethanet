# Backups

> **Status: planned, not yet implemented.** This is the next big work item
> for the lab and the most important gap to close.

## Current state

- **No Proxmox Backup Server.** I haven't stood one up yet. Container backups
  today are manual `vzdump` runs to `local` — fine for snapshot-before-change
  but **not** a disaster recovery story.
- **Media library** (`/mnt/data/jellyfin/media`): intentionally not backed up.
  Re-downloadable.
- **Photos** (`/mnt/data/immich/photos`): the riskiest data in the lab.
  Currently single-copy on the HDD. Phones still hold originals so it's
  recoverable, but there's no formal policy.
- **Container configs** (the *arr stack, NPM, Homepage, etc.): live inside the
  container rootfs on the LVM-thin pool; survive a host reboot but not a
  drive failure.

## Plan

1. **Stand up PBS** on a dedicated host — likely a more capable Raspberry Pi
   (the existing 2012 Pi 1B is too constrained) or a small Tailscale-only
   VPS. Tailnet-only, no public exposure either way.
2. **Datastore** on a USB-attached disk (or the Pi's SD card for metadata
   only with the actual chunks on USB).
3. **Backup jobs:**
   - Daily incremental for every CT (mode `snapshot`)
   - Retention: `keep-daily=7, keep-weekly=4, keep-monthly=6`
   - Encrypted at rest (PBS handles this natively)
4. **Photos:** separate sync of `/mnt/data/immich/photos` to off-site (rclone
   to a cloud bucket, encrypted).
5. **Restore drill quarterly** — a backup you've never restored isn't a
   backup.

I'll update this page once each step lands.
