#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

detect_environment() {
  if [[ -f /etc/NIXOS ]]; then
    echo "nixos"
  elif [[ -f /etc/debian_version ]]; then
    echo "debian"
  elif [[ -f /etc/redhat-release ]]; then
    echo "redhat"
  else
    echo "unknown"
  fi
}

detect_installation_state() {
  local env; env="$(detect_environment)"
  case "$env" in
    nixos)
      if [[ -d "/etc/nixos/flakes" || -f "/etc/nixos/flake.nix" || -f "./flake.nix" ]]; then
        echo "configured"
      else
        echo "fresh_nixos"
      fi
      ;;
    debian|redhat)
      if command -v nix >/dev/null 2>&1; then
        echo "nix_installed"
      else
        echo "fresh_system"
      fi
      ;;
    *)
      echo "unknown"
      ;;
  esac
}
