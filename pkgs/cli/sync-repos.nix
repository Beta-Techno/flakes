{ pkgs }:

{
  program = pkgs.writeShellApplication {
    name = "sync-repos";
    runtimeInputs = with pkgs; [
      git
      yq
    ];

    text = ''
      set -euo pipefail

      # ── Configuration ────────────────────────────────────────────
      CATALOG_FILE="''${PWD}/catalog/repos.yaml"
      REPOS_DIR="$HOME/code"

      # ── Helper functions ─────────────────────────────────────────
      die() {
        echo "Error: $1" >&2
        exit 1
      }

      # ── Check catalog file ───────────────────────────────────────
      if [ ! -f "''${CATALOG_FILE}" ]; then
        die "Catalog file not found: ''${CATALOG_FILE}"
      fi

      # ── Create repos directory ───────────────────────────────────
      mkdir -p "''${REPOS_DIR}"

      # ── Process each repository ──────────────────────────────────
      while IFS= read -r repo; do
        if [ -z "''${repo}" ]; then
          continue
        fi

        # Extract repository details
        name=$(echo "''${repo}" | yq e '.name' -)
        url=$(echo "''${repo}" | yq e '.url' -)
        kind=$(echo "''${repo}" | yq e '.kind' -)
        lang=$(echo "''${repo}" | yq e '.lang' -)
        
        # Create target path from kind and lang
        target="''${REPOS_DIR}/''${kind}/''${lang}/''${name}"
        
        echo "+ syncing ''${name} to ''${kind}/''${lang}/''${name}"

        # Create directory if it doesn't exist
        mkdir -p "$(dirname "''${target}")"

        # Clone or update repository
        if [ ! -d "''${target}/.git" ]; then
          echo "  cloning..."
          git clone "''${url}" "''${target}"
        else
          echo "  updating..."
          (cd "''${target}" && git pull --ff-only)
        fi
      done < <(yq e '.[]' "''${CATALOG_FILE}")

      echo "✅  Repository sync complete"
    '';
  };
} 