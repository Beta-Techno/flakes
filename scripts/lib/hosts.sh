#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Return newline-separated host names from flake nixosConfigurations
get_hosts() {
  local root="${1:-.}"
  local expr
  expr="let flake = builtins.getFlake (toString \"$root\"); \
        in builtins.concatStringsSep \"\n\" (builtins.attrNames flake.nixosConfigurations)"
  nix eval --impure --raw --expr "$expr" 2>/dev/null || true
}

host_exists() {
  local root="$1" host="$2"
  [[ -z "$host" ]] && return 1
  get_hosts "$root" | grep -Fxq "$host"
}

list_hosts_cmd() {
  local root="$1"; shift || true
  info "Available hosts from flake.nix:"
  local h
  while IFS= read -r h; do
    [[ -n "$h" ]] && echo "  - $h"
  done < <(get_hosts "$root" | sort)
}
