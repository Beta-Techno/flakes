#!/usr/bin/env bash
set -euo pipefail
base="$HOME/code"          # root of your working tree
catalog="catalog/repos.yaml"

yq e -o=json '.' "$catalog" | jq -c '.[]' | while read repo; do
  url=$(echo "$repo" | jq -r '.url')
  name=$(echo "$repo" | jq -r '.name')
  path=$(echo "$repo" | jq -r '.path')

  target="${base}/${path}/${name}"
  mkdir -p "$(dirname "$target")"

  if [ -d "$target/.git" ]; then
    echo "▲ Updating $name"
    git -C "$target" pull --ff-only --quiet
  else
    echo "■ Cloning  $name → $path"
    git clone --quiet "$url" "$target"
  fi
done

## Proposed Implementation

base=$HOME/code
jq -c '.[]' repos.json | while read r; do
  kind=$(jq -r '.kind' <<<"$r")
  lang=$(jq -r '.lang' <<<"$r")
  name=$(jq -r '.name' <<<"$r")
  url=$(jq  -r '.url'  <<<"$r")
  target="$base/$kind/$lang/$name"
  mkdir -p "$(dirname "$target")"
  if [ -d "$target/.git" ]; then
    git -C "$target" pull --ff-only --quiet
  else
    git clone --quiet "$url" "$target"
  fi
done