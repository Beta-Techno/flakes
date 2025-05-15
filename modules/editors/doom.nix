{ lib, pkgs, doomEmacs, doomConfig, ... }:

{
  home.packages = with pkgs; [
    emacs30-pgtk
    ripgrep fd git gcc gnumake nodejs_20
  ];

  # Put Doom in ~/.config/emacs
  xdg.configFile."emacs" = {
    source     = doomEmacs;
    recursive  = true;
  };
  xdg.configFile."doom" = {
    source     = doomConfig;
    recursive  = true;
  };

  # Adjust the activation script path:
  home.activation.doomSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail
    if [[ ! -d "$HOME/.config/emacs/.local" ]]; then
      echo "[Doom] first-time install…"
      "$HOME/.config/emacs/bin/doom" --yes install
    else
      echo "[Doom] syncing…"
      "$HOME/.config/emacs/bin/doom" --yes sync
    fi
  '';

  programs.zsh.shellAliases = {
    doomsync = "$HOME/.config/emacs/bin/doom sync --yes";
    doomup   = "$HOME/.config/emacs/bin/doom upgrade --yes";
  };
} 