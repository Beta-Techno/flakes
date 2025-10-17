#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

_action_parse_common() {
  # parses -H/--target-host, -n/--dry-run, -v/--verbose
  TARGET_HOST=""; DRY_RUN="false"; VERBOSE="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -H|--target-host) TARGET_HOST="$2"; shift 2 ;;
      -n|--dry-run)     DRY_RUN="true";  shift   ;;
      -v|--verbose)     VERBOSE="true";  shift   ;;
      --) shift; break ;;
      *) break ;;
    esac
  done
  export TARGET_HOST DRY_RUN VERBOSE
}

__nixos_rebuild() {
  local subcmd="$1"; shift
  local host="$1"; shift || true
  local root="$1"; shift || true

  local cmd=(nixos-rebuild "$subcmd" --flake "$root#$host")
  [[ "$VERBOSE" == "true" ]] && cmd+=(--verbose)
  [[ -n "$TARGET_HOST" ]] && cmd+=(--target-host "$TARGET_HOST")
  run sudo "${cmd[@]}"
}

action_deploy() {
  local root="$1"; shift
  local host=""
  if [[ $# -gt 0 && "$1" != "-"* ]]; then host="$1"; shift; fi
  _action_parse_common "$@"

  [[ -n "$host" ]] || die "Usage: nixos-deploy deploy <host> [options]"

  info "Deploying host: $host"
  if [[ "$DRY_RUN" == "true" ]]; then
    info "Dry run: building configuration only."
    __nixos_rebuild build "$host" "$root"
    ok "Dry run completed."
  else
    __nixos_rebuild switch "$host" "$root"
    ok "Deployment complete."
  fi
}

action_update() {
  local root="$1"; shift || true
  local commit="false"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --commit) commit="true"; shift ;;
      *) break ;;
    esac
  done
  need nix git
  info "Updating flake lock..."
  (cd "$root" && run nix flake update)
  ok "flake.lock updated."
  if [[ "$commit" == "true" && -d "$root/.git" ]]; then
    (cd "$root" && git add flake.lock && git commit -m "Update flake.lock")
    ok "Committed flake.lock."
  fi
}

action_status() {
  local root="$1"; shift || true
  info "System generations:"
  run nix-env -p /nix/var/nix/profiles/system --list-generations || warn "Could not list generations."

  if command -v git >/dev/null 2>&1 && [[ -d "$root/.git" ]]; then
    info "Git status for flake repo:"
    (cd "$root" && git status -s || true)
  fi

  info "Available hosts:"
  get_hosts "$root" | sort | sed 's/^/  - /'
}

action_rollback() {
  local root="$1"; shift || true
  _action_parse_common "$@"
  info "Rolling back system to previous generation..."
  local cmd=(nixos-rebuild switch --rollback)
  [[ "$VERBOSE" == "true" ]] && cmd+=(--verbose)
  [[ -n "$TARGET_HOST" ]] && cmd+=(--target-host "$TARGET_HOST")
  run sudo "${cmd[@]}"
  ok "Rollback complete."
}

action_install() {
  local root="$1"; shift
  local host="" disk="" boot_mode="auto" label="nixos" user_name="nbg" password="" assume_yes="false" no_reboot="false"
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host) host="$2"; shift 2 ;;
      --disk) disk="$2"; shift 2 ;;
      --boot) boot_mode="$2"; shift 2 ;;
      --label) label="$2"; shift 2 ;;
      --user) user_name="$2"; shift 2 ;;
      --password) password="$2"; shift 2 ;;
      -y|--yes) assume_yes="true"; shift ;;
      --no-reboot) no_reboot="true"; shift ;;
      -h|--help) echo "Usage: nixos-deploy install --host <host> --disk </dev/XXX> [options]"; return ;;
      *) break ;;
    esac
  done
  
  [[ -n "$host" && -n "$disk" ]] || die "install requires --host and --disk"
  need nix nixos-install lsblk

  # Auto-detect boot mode if not specified
  if [[ "$boot_mode" == "auto" ]]; then
    if [[ -d /sys/firmware/efi/efivars ]]; then
      boot_mode="uefi"
    else
      boot_mode="bios"
    fi
  fi

  info "Installing NixOS ($host) on $disk (boot mode: $boot_mode)"
  
  # Safety check
  if [[ "$assume_yes" != "true" ]]; then
    warn "This will ERASE $disk completely."
    if ! confirm_wipe; then
      die "Installation aborted"
    fi
  fi

  # Pre-flight cleanup
  info "Cleaning up existing mounts..."
  run umount -R /mnt 2>/dev/null || true
  run swapoff -a 2>/dev/null || true

  # Create disko spec
  local disko_spec="/tmp/disko.nix"
  if [[ "$boot_mode" == "bios" ]]; then
    cat > "$disko_spec" << EOF
{ lib, ... }: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "$disk";
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
              extraArgs = [ "-L" "$label" ];
            };
          };
        };
      };
    };
  };
}
EOF
  else
    cat > "$disko_spec" << EOF
{ lib, ... }: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "$disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              extraArgs = [ "-n" "EFI" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "noatime" ];
              extraArgs = [ "-L" "$label" ];
            };
          };
        };
      };
    };
  };
}
EOF
  fi

  # Partition and format with disko
  info "Partitioning and formatting disk with disko..."
  run nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko "$disko_spec"

  info "Mounting filesystems..."
  run nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode mount "$disko_spec"

  # Clone flake to target
  local mnt="/mnt"
  local flake_dir="$mnt/etc/nixos/flakes"
  info "Cloning flake to $flake_dir..."
  run mkdir -p "$flake_dir"
  
  if command -v git >/dev/null 2>&1; then
    run git clone --depth=1 --branch main "$root" "$flake_dir"
  else
    run nix shell nixpkgs#git -c git clone --depth=1 --branch main "$root" "$flake_dir"
  fi

  # Fix boot mode if needed
  if [[ "$boot_mode" == "uefi" ]]; then
    local host_file="$flake_dir/nixos/hosts/workstations/${host}.nix"
    if [[ -f "$host_file" ]] && grep -q "boot/bios-grub.nix" "$host_file"; then
      info "Switching $host to UEFI (sd-boot) in cloned flake..."
      run sed -i 's#boot/bios-grub.nix#boot/uefi-sdboot.nix#' "$host_file"
    fi
  fi

  # Install NixOS
  info "Installing NixOS (this may take a while)..."
  run nixos-install --root "$mnt" --flake "$flake_dir#$host" --no-root-passwd --no-channel-copy

  # Set user password
  if [[ -n "$password" ]]; then
    info "Setting password for $user_name (non-interactive)..."
    run nixos-enter --root "$mnt" -- sh -c "echo '$user_name:$password' | chpasswd"
  else
    echo
    echo "Set a password for $user_name:"
    run nixos-enter --root "$mnt" -- passwd "$user_name" || true
  fi

  run sync

  # Reboot or exit
  if [[ "$no_reboot" == "true" ]]; then
    ok "Installation complete. You may 'umount -R /mnt' and reboot manually."
  else
    ok "Installation complete. Rebooting into new system..."
    run reboot
  fi
}

action_doctor() {
  info "Doctor: verifying prerequisites…"
  local ok_all=true
  for b in bash nix nixos-rebuild; do
    if ! command -v "$b" >/dev/null 2>&1; then
      err "Missing: $b"
      ok_all=false
    fi
  done
  $ok_all && ok "All core prerequisites found." || die "Please install the missing tools."
}
