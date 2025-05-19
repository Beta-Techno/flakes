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
      REPOS_DIR="$HOME/repos"

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

        # Extract repository name and path
        name="''${repo%%:*}"
        path="''${repo#*:}"
        full_path="''${REPOS_DIR}/''${path}"

        echo "+ syncing ''${name} to ''${path}"

        # Create directory if it doesn't exist
        mkdir -p "$(dirname "''${full_path}")"

        # Clone or update repository
        if [ ! -d "''${full_path}/.git" ]; then
          echo "  cloning..."
          git clone "git@github.com:Beta-Techno/''${name}.git" "''${full_path}"
        else
          echo "  updating..."
          (cd "''${full_path}" && git pull --ff-only)
        fi
      done < <(yq e '.repos[] | .name + ":" + .path' "''${CATALOG_FILE}")

      echo "✅  Repository sync complete"
    '';
  };
} 