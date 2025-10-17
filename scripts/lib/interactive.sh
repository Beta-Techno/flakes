#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

show_banner() {
cat <<'B'
╔══════════════════════════════════════════════════════════════╗
║                    NixOS Deployment Tool                     ║
╚══════════════════════════════════════════════════════════════╝
B
}

confirm() {
  local prompt="${1:-Proceed?}"; local default="${2:-y}"
  local yn
  while true; do
    read -r -p "$prompt (y/n) [${default}]: " yn || yn="$default"
    yn="${yn:-$default}"
    case "$yn" in
      y|Y) echo y; return 0 ;;
      n|N) echo n; return 1 ;;
      *)   echo "Please answer y or n." ;;
    esac
  done
}

# Special confirm for destructive operations
confirm_wipe() {
  local prompt="${1:-Type 'WIPE' to continue}"
  local answer
  read -r -p "$prompt: " answer
  [[ "$answer" == "WIPE" ]]
}

select_from_list() {
  # usage: select_from_list "Prompt" array_name -> echoes selection
  local prompt="$1"; shift
  local -n _arr="$1"
  (( ${#_arr[@]} > 0 )) || { echo ""; return 1; }
  echo "$prompt"
  local i=1
  for item in "${_arr[@]}"; do
    echo "  $i) $item"
    ((i++))
  done
  local choice
  while true; do
    read -r -p "Select (1-${#_arr[@]}): " choice
    [[ "$choice" =~ ^[0-9]+$ ]] && (( choice>=1 && choice<=${#_arr[@]} )) && {
      echo "${_arr[choice-1]}"; return 0; }
    echo "Invalid selection."
  done
}

select_host() {
  local root="$1"
  mapfile -t hosts < <(get_hosts "$root")
  select_from_list "Which host configuration?" hosts
}

select_disk() {
  local disks=()
  while IFS= read -r disk; do
    disks+=("$disk")
  done < <(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}')
  select_from_list "Which disk to install to?" disks
}

interactive_main() {
  local root="$1"
  show_banner
  local state; state="$(detect_installation_state)"
  case "$state" in
    fresh_system)
      info "Detected fresh non-NixOS system."
      if [[ "$(confirm 'Install NixOS on this system?')" == "y" ]]; then
        local host; host="$(select_host "$root")"
        local disk; disk="$(select_disk)"
        [[ -z "$host" || -z "$disk" ]] && die "Selection aborted."
        info "Installing NixOS ($host) on $disk"
        action_install "$root" --host "$host" --disk "$disk"
      fi
      ;;
    fresh_nixos)
      info "Detected fresh NixOS (no flake checkout configured)."
      local host; host="$(select_host "$root")"
      [[ -z "$host" ]] && die "No host selected."
      [[ "$(confirm 'Deploy now?')" == "y" ]] || exit 0
      action_deploy "$root" "$host"
      ;;
    configured)
      info "Detected configured NixOS."
      local host; host="$(select_host "$root")"
      [[ -z "$host" ]] && die "No host selected."
      if [[ "$(confirm 'Dry run first?')" == "y" ]]; then
        action_deploy "$root" "$host" --dry-run
        [[ "$(confirm 'Deploy for real?')" == "y" ]] && action_deploy "$root" "$host"
      else
        action_deploy "$root" "$host"
      fi
      ;;
    *)
      die "Unknown system state."
      ;;
  esac
}
