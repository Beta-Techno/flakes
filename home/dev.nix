###############################################################################
#  home/dev.nix — Rob’s Home-Manager profile (Ubuntu 24 · Intel Iris 6100)
###############################################################################
{ config, pkgs, lib, ... }:

let
  nixBin = "${pkgs.nix}/bin/nix";

  # ---- helpers -------------------------------------------------------------
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec ${nixBin} run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  # absolute icon path shipped by Alacritty (choose any size you like)
  alacrittyIcon =
    "${pkgs.alacritty}/share/icons/hicolor/128x128/apps/Alacritty.png";
in
{
  ########################  Required #########################################
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";
  targets.genericLinux.enable = true;

  ########################  Launcher #########################################
  home.activation.installAlacrittyLauncher =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"

      # remove any previous Alacritty launchers we created
      rm -f "$apps/alacritty.desktop"

      cat > "$apps/alacritty.desktop" <<EOF
[Desktop Entry]
Name=Alacritty
GenericName=Terminal
Exec=${alacrittyWrapped}/bin/alacritty
Icon=${alacrittyIcon}
Type=Application
Categories=System;TerminalEmulator;
Terminal=false
EOF
      ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
    '';

  ########################  Packages #########################################
  home.packages = with pkgs; [
    # CLI
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron GUI (wrapped)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode) (lib.lowPrio pkgs.postman)

    # JetBrains IDEs
    jetbrains.datagrip jetbrains.rider

    # Other GUI apps
    emacs29-pgtk
    alacrittyWrapped
    google-chrome

    # Fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ########################  Shell / tools (unchanged) ########################
  programs.zsh.enable           = true;
  programs.zsh.oh-my-zsh.enable = true;
  programs.zsh.oh-my-zsh.theme  = "agnoster";

  programs.tmux.enable      = true;
  programs.tmux.extraConfig = ''
    set -g mouse on
    set -g history-limit 100000
  '';

  programs.git = {
    enable    = true;
    userName  = "Rob";
    userEmail = "rob@example.com";
  };

  home.shellAliases = {
    k="kubectl"; dcu="docker compose up -d"; dcd="docker compose down";
  };

  fonts.fontconfig.enable = true;

  ########################  Ghostty terminfo, cloudflared  ###################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}