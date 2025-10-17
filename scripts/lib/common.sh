#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

log() {
  local level="$1"; shift
  printf '[%s] %s\n' "$level" "$*" >&2
}
info() { log "INFO" "$@"; }
ok()   { log "SUCCESS" "$@"; }
warn() { log "WARNING" "$@"; }
err()  { log "ERROR" "$@"; }

die() {
  err "$@"
  exit 1
}

run() {
  # Echo command then execute
  printf '+ %q' "$@" >&2; echo >&2
  "$@"
}

need() {
  local missing=()
  for b in "$@"; do
    command -v "$b" >/dev/null 2>&1 || missing+=("$b")
  done
  if ((${#missing[@]})); then
    die "Missing required commands: ${missing[*]}"
  fi
}

ensure_flake_root() {
  local root="${1:-.}"
  [[ -f "$root/flake.nix" ]] || return 1
  return 0
}

# Pretty error context for traps
__on_err() {
  local exit_code=$?
  err "Command failed at line ${BASH_LINENO[0]} (exit $exit_code)"
  exit "$exit_code"
}
trap __on_err ERR
