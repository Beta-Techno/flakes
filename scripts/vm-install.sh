#!/usr/bin/env bash
set -euo pipefail

# ── UI helpers ──────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log(){ printf "%b[%s]%b %s\n" "$BLUE" "INFO" "$NC" "$*"; }
ok(){  printf "%b[%s]%b %s\n" "$GREEN" "OK"   "$NC" "$*"; }
warn(){printf "%b[%s]%b %s\n" "$YELLOW" "WARN" "$NC" "$*"; }
die(){ printf "%b[%s]%b %s\n" "$RED" "ERR"  "$NC" "$*"; exit 1; }

# Elevate if needed
if [ "${EUID:-0}" -ne 0 ]; then exec sudo -E bash "$0" "$@"; fi

# ── Defaults & args ─────────────────────────────────────────────────────────
HOST="nick-vm"
REPO_URL="https://github.com/Beta-Techno/flakes.git"
BRANCH="main"
LABEL="nixos"
USER_NAME="nbg"
PASSWORD=""
DISK=""
BOOT_MODE="auto"      # auto|bios|uefi
ASSUME_YES="false"
NO_REBOOT="false"

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --host <name>        Flake host (default: nick-vm)
  --repo <url>         Flake repo URL (default: https://github.com/Beta-Techno/flakes.git)
  --branch <name>      Git branch to clone (default: main)
  --disk <path>        Target disk (/dev/disk/by-id/... or /dev/sdX|vdX). Auto-detects if omitted.
  --boot <mode>        auto | bios | uefi (default: auto)
  --label <str>        Filesystem label for / (default: nixos)
  --user <name>        Local user to set password for (default: nbg)
  --password <pass>    Set user password non-interactively (optional)
  -y, --yes            Do not prompt before wiping disk
  --no-reboot          Do not reboot at the end
  -h, --help           Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2;;
    --repo) REPO_URL="$2"; shift 2;;
    --branch) BRANCH="$2"; shift 2;;
    --disk) DISK="$2"; shift 2;;
    --boot) BOOT_MODE="$2"; shift 2;;
    --label) LABEL="$2"; shift 2;;
    --user) USER_NAME="$2"; shift 2;;
    --password) PASSWORD="$2"; shift 2;;
    -y|--yes) ASSUME_YES="true"; shift;;
    --no-reboot) NO_REBOOT="true"; shift;;
    -h|--help) usage; exit 0;;
    *) die "Unknown arg: $1 (see --help)";;
  esac
done

# ── Helpers ────────────────────────────────────────────────────────────────
detect_disk() {
  # Prefer a stable by-id path, skipping cdroms
  if ls /dev/disk/by-id/* >/dev/null 2>&1; then
    for d in /dev/disk/by-id/*; do
      [ -e "$d" ] || continue
      [[ "$d" =~ (cdrom|DVD|CD) ]] && continue
      tgt="$(readlink -f "$d")"
      [ "$(lsblk -ndo TYPE "$tgt" 2>/dev/null || true)" = "disk" ] && { echo "$d"; return; }
    done
  fi
  # Fallback to the first "disk" from lsblk
  lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1; exit}'
}

need() { command -v "$1" >/dev/null 2>&1 || die "Missing $1"; }

# ── Detect disk & boot mode ────────────────────────────────────────────────
[ -n "$DISK" ] || DISK="$(detect_disk)"
[ -n "$DISK" ] || die "Could not detect a target disk. Pass --disk /dev/…"

if [[ "$BOOT_MODE" == "auto" ]]; then
  if [ -d /sys/firmware/efi/efivars ]; then BOOT_MODE="uefi"; else BOOT_MODE="bios"; fi
fi
[[ "$BOOT_MODE" =~ ^(bios|uefi)$ ]] || die "--boot must be bios|uefi|auto"

log "Target disk : $DISK"
log "Boot mode   : $BOOT_MODE"
log "Flake host  : $HOST"
log "Flake repo  : $REPO_URL ($BRANCH)"
warn "This will ERASE ${DISK} completely."

if [[ "$ASSUME_YES" != "true" ]]; then
  read -r -p "Type 'WIPE' to continue: " ANSWER
  [[ "$ANSWER" == "WIPE" ]] || die "Aborted."
fi

# ── Pre-flight ─────────────────────────────────────────────────────────────
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true
need nix

# ── Disko spec ─────────────────────────────────────────────────────────────
DISKO=/tmp/disko.nix
if [ "$BOOT_MODE" = "bios" ]; then
  cat >"$DISKO" <<EOF
{ lib, ... }: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "${DISK}";
      content = {
        type = "gpt";
        partitions = {
          boot = { type = "EF02"; size = "1M"; };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "noatime" ];
              label = "${LABEL}";
            };
          };
        };
      };
    };
  };
}
EOF
else
  cat >"$DISKO" <<EOF
{ lib, ... }: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "${DISK}";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "512M";
            content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "noatime" ];
              label = "${LABEL}";
            };
          };
        };
      };
    };
  };
}
EOF
fi

# ── Wipe/partition/format & mount ──────────────────────────────────────────
log "Partitioning + formatting with disko…"
nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko "$DISKO"

log "Mounting filesystems…"
nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount "$DISKO"

# ── Put the flake onto the target ──────────────────────────────────────────
MNT=/mnt
FLAKE_DIR="$MNT/etc/nixos/flakes"
mkdir -p "$FLAKE_DIR"

log "Cloning flake → $FLAKE_DIR …"
if command -v git >/dev/null 2>&1; then
  git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$FLAKE_DIR"
else
  nix shell nixpkgs#git -c git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$FLAKE_DIR"
fi

# If UEFI boot is detected but host imports BIOS profile, flip it on the cloned copy
if [ "$BOOT_MODE" = "uefi" ]; then
  HOST_FILE="$FLAKE_DIR/nixos/hosts/workstations/${HOST}.nix"
  if [ -f "$HOST_FILE" ] && grep -q "boot/bios-grub.nix" "$HOST_FILE"; then
    log "Switching ${HOST} to UEFI (sd-boot) in the cloned flake…"
    sed -i 's#boot/bios-grub.nix#boot/uefi-sdboot.nix#' "$HOST_FILE"
  fi
fi

# ── Install the selected host from the flake ───────────────────────────────
log "Installing NixOS (this can take a while)…"
nixos-install --root "$MNT" --flake "$FLAKE_DIR#$HOST" --no-root-passwd \
  --extra-experimental-features "nix-command flakes"

ok "Install finished."

# ── Set user password ──────────────────────────────────────────────────────
if [ -n "$PASSWORD" ]; then
  log "Setting password for ${USER_NAME} (non-interactive)…"
  nixos-enter --root "$MNT" -- sh -c "echo '${USER_NAME}:${PASSWORD}' | chpasswd"
else
  echo
  echo "Set a password for ${USER_NAME}:"
  nixos-enter --root "$MNT" -- passwd "${USER_NAME}" || true
fi

sync

# ── Reboot ────────────────────────────────────────────────────────────────
if [ "$NO_REBOOT" = "true" ]; then
  ok "Done. You may 'umount -R /mnt' and reboot manually."
else
  ok "Rebooting into your new system…"
  reboot
fi
