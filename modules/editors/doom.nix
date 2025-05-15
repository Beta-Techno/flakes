{ lib, pkgs, doomEmacs, doomConfig, ... }:

{
  home.packages = with pkgs; [
    emacs30-pgtk
    ripgrep fd git gcc gnumake nodejs_20
  ];

  home.file.".emacs.d" = { source = doomEmacs;  recursive = true; };
  home.file.".doom.d"  = { source = doomConfig; recursive = true; };

  home.activation.doomSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail
    if [[ ! -d "$HOME/.emacs.d/.local" ]]; then
      echo "[Doom] first-time install…"
      "$HOME/.emacs.d/bin/doom" --yes install
    else
      echo "[Doom] syncing…"
      "$HOME/.emacs.d/bin/doom" --yes sync
    fi
  '';

  programs.zsh.shellAliases = {
    doomsync = "$HOME/.emacs.d/bin/doom sync --yes";
    doomup   = "$HOME/.emacs.d/bin/doom upgrade --yes";
  };
} 