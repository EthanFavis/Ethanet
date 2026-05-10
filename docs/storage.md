# Storage

Two physical drives, two roles: fast NVMe for the OS and container rootfs,
slow bulk HDD for the media and photos library.

```mermaid
flowchart LR
    subgraph NVMe["256 GB NVMe (KIOXIA KBG40ZNV256G)"]
        EFI[EFI · 1 GB · /boot/efi]
        LVM[LVM2 PV · 237 GB]
        LVM --> Swap[swap · 8 GB]
        LVM --> Root[pve-root · 69 GB · /]
        LVM --> Data[pve-data · 141 GB · LVM-thin]
        Data --> CT100[CT100 · 32 GB]
        Data --> CT102[CT102 · 20 GB]
        Data --> CT104[CT104 · 16 GB]
        Data --> CT108[CT108 · 12 GB]
        Data --> Etc[8 more containers...]
    end
    subgraph HDD["1 TB HDD (HGST 2.5\")"]
        Mnt["/mnt/data · ext4 · 916 GB"]
        Mnt --> Media["jellyfin/media (262 GB)"]
        Mnt --> Photos["immich/photos"]
        Mnt --> DLs["downloads (2.3 GB)"]
        Mnt --> ArrCfg["sonarr / radarr / etc."]
    end
```

## Proxmox storage pools

From `/etc/pve/storage.cfg`:

```ini
dir: local
    path /var/lib/vz
    content iso,vztmpl,backup,import

lvmthin: local-lvm
    thinpool data
    vgname pve
    content rootdir,images
```

- **`local`** — directory on the root filesystem; holds ISOs, container
  templates, and (for now) local backup dumps. ~70 GB.
- **`local-lvm`** — LVM-thin pool on the NVMe; holds every container's
  rootfs. ~141 GB, currently 60 % used.

The bulk HDD is **not** a Proxmox storage pool — it's just a regular ext4
filesystem mounted at `/mnt/data`, exposed to containers via bind mounts.

## Bind mounts (the `/mnt/data` strategy)

Several containers share `/mnt/data` via per-service bind mounts in their
`pct config`:

| Container | Bind mount | Inside CT |
|---|---|---|
| immich (102) | `/mnt/data/immich/photos` | `/photos` |
| immich (102) | `/mnt/data/immich/config` | `/config` |
| qbittorrent (103) | `/mnt/data/downloads` | `/downloads` |
| jellyfin (104) | `/mnt/data/jellyfin/media` | `/media` |
| jellyfin (104) | `/mnt/data/jellyfin/config` | `/config` |
| sonarr (107) | `/mnt/data` | `/data` |
| radarr (106) | `/mnt/data` | `/data` |

The *arr containers see the full `/mnt/data` tree so they can hardlink
between `downloads/` and the library — qBittorrent finishes a torrent into
`/downloads`, Sonarr/Radarr move-by-hardlink it into `jellyfin/media/...`,
and Jellyfin picks it up. No file is ever copied twice on disk.

## fstab

```
UUID=d439df67-… /mnt/data ext4 defaults 0 2
```

The HDD is plain ext4 with default options — no RAID, no LVM on this drive.
Loss of the drive means losing the media library and (currently) the only
copy of the Immich photo originals. Closing that gap is the top item on
the [roadmap](roadmap.md); see [backups.md](backups.md) for the plan.

## Capacity (current)

| Pool | Size | Used | Free |
|---|---:|---:|---:|
| `local` (NVMe dir) | 70 GB | 8 GB | 59 GB |
| `local-lvm` (NVMe thin) | 141 GB | 86 GB | 55 GB |
| `/mnt/data` (HDD) | 916 GB | 264 GB | 606 GB |
