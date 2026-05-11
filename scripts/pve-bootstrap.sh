#!/usr/bin/env bash
# pve-bootstrap.sh — post-fresh-install setup for the homelab Proxmox host.
#
# Runs the community-scripts post-install, mounts /mnt/data (existing ext4,
# never formats), installs Tailscale on the host, and offers a menu to spin
# up each homelab LXC plus Tailscale-in-LXC for any existing containers.
#
# Usage: scp this file to the PVE host, then as root:  bash pve-bootstrap.sh

set -euo pipefail

CS_RAW="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
DATA_MOUNT="/mnt/data"
DATA_DIRS=(
  "jellyfin/media"
  "jellyfin/config"
  "immich/photos"
  "immich/config"
  "downloads"
)

# Services available via community-scripts (filename without .sh under ct/).
SERVICES=(
  jellyfin
  sonarr
  radarr
  prowlarr
  qbittorrent
  jellyseerr
  flaresolverr
  immich
  nginxproxymanager
  homepage
  beszel
  crafty-controller
)

c_red()   { printf '\033[31m%s\033[0m\n' "$*"; }
c_green() { printf '\033[32m%s\033[0m\n' "$*"; }
c_blue()  { printf '\033[34m%s\033[0m\n' "$*"; }
c_yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

hr() { printf '\n%s\n' "------------------------------------------------------------"; }
banner() { hr; c_blue "==> $*"; hr; }

pause() {
  local msg="${1:-Press ENTER to continue, Ctrl-C to abort}"
  printf '\n'; c_yellow "$msg"; read -r _
}

confirm() {
  local prompt="${1:-Proceed?} [y/N] "
  local ans
  read -rp "$prompt" ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

# ---------- 1. Sanity checks ----------
preflight() {
  banner "Preflight checks"
  if [[ $EUID -ne 0 ]]; then
    c_red "Must run as root."; exit 1
  fi
  if [[ ! -d /etc/pve ]] || ! command -v pveversion >/dev/null; then
    c_red "This doesn't look like a Proxmox host (no /etc/pve or pveversion)."
    exit 1
  fi
  c_green "Running as root on $(pveversion | head -1)"
  if ! ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then
    c_red "No outbound connectivity (ping 1.1.1.1 failed)."; exit 1
  fi
  c_green "Network OK"
}

# ---------- 2. Community-scripts post-install ----------
run_post_install() {
  banner "Step 1/5: community-scripts Proxmox VE Post Install"
  c_yellow "Interactive prompts: disables enterprise repo, enables no-sub,"
  c_yellow "removes subscription nag, etc. Answer them as you like."
  confirm "Run post-install script now?" || { c_yellow "Skipped."; return; }
  bash -c "$(curl -fsSL ${CS_RAW}/tools/pve/post-pve-install.sh)" || true
  pause "Review output above. ENTER to continue."
}

# ---------- 3. Mount /mnt/data (existing ext4, never format) ----------
mount_data() {
  banner "Step 2/5: mount data HDD at ${DATA_MOUNT}"

  if mountpoint -q "$DATA_MOUNT"; then
    c_green "${DATA_MOUNT} is already mounted. Skipping."
    return
  fi

  c_yellow "Available block devices (excluding pve LVM):"
  lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT,UUID | grep -vE '^(loop|sr|nvme.+pve)'
  echo
  read -rp "Enter the partition to mount as ${DATA_MOUNT} (e.g. sda1): " part
  local dev="/dev/${part}"
  if [[ ! -b "$dev" ]]; then
    c_red "$dev is not a block device. Aborting mount step."; return
  fi

  local fstype
  fstype=$(blkid -o value -s TYPE "$dev" || true)
  if [[ "$fstype" != "ext4" ]]; then
    c_red "$dev filesystem is '${fstype:-unknown}', expected ext4."
    c_red "Refusing to touch it. Mount manually if needed."
    return
  fi

  local uuid
  uuid=$(blkid -o value -s UUID "$dev")
  c_green "Found ext4 on $dev (UUID=$uuid)"

  mkdir -p "$DATA_MOUNT"

  if grep -q "$uuid" /etc/fstab; then
    c_yellow "fstab already references this UUID."
  else
    echo "UUID=${uuid} ${DATA_MOUNT} ext4 defaults 0 2" >> /etc/fstab
    c_green "Added fstab entry."
  fi

  mount "$DATA_MOUNT"
  c_green "Mounted ${DATA_MOUNT}:"
  df -h "$DATA_MOUNT"

  c_blue "Ensuring standard directory tree exists..."
  for d in "${DATA_DIRS[@]}"; do
    mkdir -p "${DATA_MOUNT}/${d}"
    echo "  ${DATA_MOUNT}/${d}"
  done
}

# ---------- 4. Tailscale on the host ----------
install_tailscale_host() {
  banner "Step 3/5: install Tailscale on the host"
  if command -v tailscale >/dev/null; then
    c_green "tailscale already installed: $(tailscale version | head -1)"
  else
    confirm "Install Tailscale via official installer?" || { c_yellow "Skipped."; return; }
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
  if ! tailscale status >/dev/null 2>&1; then
    c_yellow "Run 'tailscale up' to authenticate the host onto your tailnet."
    confirm "Run 'tailscale up' now (will print an auth URL)?" && tailscale up || true
  else
    c_green "Tailscale already authenticated."
  fi
}

# ---------- 5. Tailscale into existing LXCs ----------
tailscale_into_lxcs() {
  banner "Step 4/5: install Tailscale into existing LXCs"
  local cts
  cts=$(pct list 2>/dev/null | awk 'NR>1 {print $1}')
  if [[ -z "$cts" ]]; then
    c_yellow "No LXCs found yet. Skip — re-run this script after creating containers."
    return
  fi
  c_yellow "Existing LXCs:"
  pct list
  echo
  for ctid in $cts; do
    if confirm "Run add-tailscale-lxc.sh against CT ${ctid}?"; then
      CTID="$ctid" bash -c "$(curl -fsSL ${CS_RAW}/tools/addon/add-tailscale-lxc.sh)" || true
    fi
  done
}

# ---------- 6. Service install menu ----------
install_services() {
  banner "Step 5/5: install homelab services"
  c_yellow "Each service prompts for CTID/resources interactively."
  c_yellow "Suggested CTIDs (from runbook): 100-199 range."
  echo
  PS3=$'\nPick a service to install (or "0" to finish): '
  local opts=("${SERVICES[@]}" "ALL (in order)" "Done")
  select opt in "${opts[@]}"; do
    case "$opt" in
      "Done"|"") c_green "Service install loop finished."; break ;;
      "ALL (in order)")
        for s in "${SERVICES[@]}"; do
          c_blue "--- installing $s ---"
          bash -c "$(curl -fsSL ${CS_RAW}/ct/${s}.sh)" || c_red "$s failed; continuing."
          pause "Review output for $s. ENTER for next."
        done
        ;;
      *)
        if [[ " ${SERVICES[*]} " == *" ${opt} "* ]]; then
          bash -c "$(curl -fsSL ${CS_RAW}/ct/${opt}.sh)" || c_red "$opt failed."
        else
          c_red "Unknown choice."
        fi
        ;;
    esac
  done
}

main() {
  preflight
  run_post_install
  mount_data
  install_tailscale_host
  tailscale_into_lxcs
  install_services
  hr
  c_green "Bootstrap complete."
  c_yellow "Next: bind-mount /mnt/data paths into each LXC (see runbooks/add-lxc.md),"
  c_yellow "      run add-tailscale-lxc.sh in any new CTs, then rerun this script's"
  c_yellow "      step 4 to push Tailscale into them."
}

main "$@"
