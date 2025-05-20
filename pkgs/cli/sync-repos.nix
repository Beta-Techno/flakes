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
      yq e -o=tsv '.[] | [.name, .url, .kind, .lang] | @tsv' "''${CATALOG_FILE}" \
      | while IFS=$'\t' read -r name url kind lang; do
          echo "+ syncing ''${name} to ''${kind}/''${lang}/''${name}"

          target="''${REPOS_DIR}/''${kind}/''${lang}/''${name}"
          mkdir -p "$(dirname "''${target}")"

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