# Hardware

A single small-form-factor business desktop. The whole lab fits on a desk
shelf, runs on a 35 W TDP CPU, and is silent under normal load.

## Host

| Component | Spec |
|---|---|
| Model | HP ProDesk 400 G6 Desktop Mini PC |
| BIOS | HP S23 Ver. 02.22.00 (UEFI) |
| CPU | Intel **Core i5-10500T** — 6 cores / 12 threads, 2.3 GHz base, Comet Lake (10th gen) |
| TDP | 35 W (low-power "T" SKU) |
| iGPU | Intel UHD Graphics 630 — used for Quick Sync transcoding |
| Memory | 12 GB DDR4 SODIMM — 8 GB Hynix + 4 GB Micron, 2400 MT/s configured (board supports 32 GB max across 2 SODIMM slots) |
| Boot drive | 256 GB NVMe — KIOXIA KBG40ZNV256G |
| Bulk storage | 1 TB 2.5" SATA HDD — HGST HTS721010A9E630 (7200 rpm) |
| Network | 1× onboard 1 GbE (Intel I219-LM via the chipset) |
| Form factor | Mini PC (~1L chassis) |

## Networking gear

| Component | Spec |
|---|---|
| Router / Gateway | Ubiquiti **UniFi Cloud Gateway Ultra** (UCG-Ultra) — the `192.168.88.1` gateway + on-box UniFi controller (replaced the previous MikroTik) |
| Switch | Netgear GS108 — 8-port unmanaged gigabit switch *(planned: replace with a UniFi PoE switch)* |
| DNS appliance | Raspberry Pi 1 Model B Rev 2 — see [services/pi-hole.md](services/pi-hole.md) |

## Capacity headroom

- **CPU:** the 6c/12t i5-10500T idles around 2–4 % under the current
  workload — plenty of room for more containers.
- **RAM:** 12 GB is the current bottleneck. One free SODIMM slot; replacing the
  4 GB stick with another 8 GB or 16 GB module would bring the lab to 16/24 GB
  and is the next planned upgrade.
- **Storage:** the LVM-thin pool is at ~69 % used; `/mnt/data` (media) is at
  **75 % of 916 GB** — filling up; the next storage decision is approaching.

## Why this hardware

I picked a corporate-refurb mini PC because the price-per-feature was hard to
beat: Intel Quick Sync for transcoding, M.2 NVMe, room for a 2.5" drive, two
SODIMM slots up to 32 GB, and a 35 W TDP that means it stays quiet on a
shelf. The trade-offs — single onboard NIC, no ECC, no PCIe expansion —
don't matter for a hobby lab where workloads are container-portable and
recoverable from backup.

## Raw inventory (sanitized)

The full hardware dumps live in `_inventory/host/` (gitignored). The key
non-sensitive bits from `dmidecode`:

```
System:    HP ProDesk 400 G6 Desktop Mini PC (SKU 9AG50AV)
BIOS:      HP S23 02.22.00, 12/31/2024
Memory:    8 GB Hynix HMA81GS6DJR8N-XN (DIMM1, ChannelB, 3200 MT/s)
           4 GB Micron 4ATF51264HZ-2G3E2 (DIMM3, ChannelA, 2400 MT/s)
Processor: Intel(R) Core(TM) i5-10500T CPU @ 2.30GHz, 6c/12t, 35W TDP
Onboard:   IGD video (UHD 630), Onboard LAN (Intel I219-LM)
```
