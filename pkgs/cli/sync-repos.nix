{ pkgs }:

{
  program = pkgs.writeShellApplication {
    name = "sync-repos";
    runtimeInputs = with pkgs; [
      git
      yq-go       # go v4 -> has 'yq e', 'yq eval', etc.
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
      yq e '.[]' "''${CATALOG_FILE}" | while read -r repo; do
        if [ -z "''${repo}" ]; then
          continue
        fi

        # Extract repository details
        name=$(yq e '.name' - <<< "''${repo}")
        url=$(yq e '.url' - <<< "''${repo}")
        kind=$(yq e '.kind' - <<< "''${repo}")
        lang=$(yq e '.lang' - <<< "''${repo}")
        
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
      done

      echo "✅  Repository sync complete"
    '';
  };
} 