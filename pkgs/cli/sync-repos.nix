{ pkgs, lib }:

pkgs.writeShellApplication {
  name = "sync-repos";
  runtimeInputs = with pkgs; [
    git
    yq
    parallel
  ];

  text = ''
    set -euo pipefail

    # ── Configuration ────────────────────────────────────────────
    CATALOG_FILE="$(dirname "$0")/../../catalog/repos.yaml"
    CODE_ROOT="''${ACME_CODE_ROOT:-$HOME/code}"

    # ── Helper functions ─────────────────────────────────────────
    die() {
      echo "Error: $1" >&2
      exit 1
    }

    clone_or_update() {
      local repo="$1"
      local kind="$2"
      local lang="$3"
      local name="$4"
      
      # Create structured path
      local target_dir="$CODE_ROOT/$kind/$lang/$name"
      
      if [ ! -d "$target_dir" ]; then
        echo "+ cloning $repo to $target_dir"
        mkdir -p "$target_dir"
        git clone "git@github.com:$repo.git" "$target_dir"
      else
        echo "+ updating $repo in $target_dir"
        (cd "$target_dir" && git pull --ff-only)
      fi
    }
    export -f clone_or_update

    # ── Check catalog file ───────────────────────────────────────
    if [ ! -f "$CATALOG_FILE" ]; then
      die "Catalog file not found: $CATALOG_FILE"
    fi

    # ── Process repositories ──────────────────────────────────────
    echo "+ syncing repositories"
    mkdir -p "$CODE_ROOT"
    
    # If yq is not available, use a simple grep-based approach
    if command -v yq >/dev/null 2>&1; then
      yq -r '.[] | [.url, .kind, .lang, .name] | @tsv' "$CATALOG_FILE" | \
        parallel --colsep '\t' clone_or_update
    else
      # Simple grep-based approach for basic repo syncing
      while IFS= read -r line; do
        if [[ $line == *"name:"* ]]; then
          name=$(echo "$line" | cut -d' ' -f2)
          read -r url_line
          url=$(echo "$url_line" | cut -d' ' -f2)
          read -r kind_line
          kind=$(echo "$kind_line" | cut -d' ' -f2)
          read -r lang_line
          lang=$(echo "$lang_line" | cut -d' ' -f2)
          clone_or_update "$url" "$kind" "$lang" "$name"
        fi
      done < "$CATALOG_FILE"
    fi

    echo "✅  Repository sync complete"
  '';
} 