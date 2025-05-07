###############################################################################
#  home/dev.nix — Rob’s Home-Manager profile (Ubuntu 24, Intel Iris 6100)
###############################################################################
{ config, pkgs, lib, ... }:

let
  nixBin = "${pkgs.nix}/bin/nix";

  # Wrap Electron apps with --no-sandbox
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # Alacritty wrapper → nixGLIntel
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec ${nixBin} run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  # Script that copies every icon and renames it to lower-case “alacritty.*”
  copyAlacrittyIcons = pkgs.writeShellApplication {
    name = "copy-alacritty-icons";
    text = ''
      set -eu
      theme="$HOME/.local/share/icons/hicolor"
      shopt -s nullglob
      for file in ${pkgs.alacritty}/share/icons/hicolor/*/apps/*; do
        rel="${file#*/hicolor/}"              # 512x512/apps/Alacritty.png
        size="${rel%%/*}"                     # 512x512  or  scalable
        dest="$theme/$size/apps"
        mkdir -p "$dest"
        cp -f "$file" "$dest/alacritty.${file##*.}"
      done
      gtk-update-icon-cache "$theme" || true
    '';
    runtimeInputs = [ pkgs.gtk3 ];
  };
in
{
  ################################  basics  ##################################
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";
  targets.genericLinux.enable = true;

  ################################  launcher  ################################
  home.activation.installAlacrittyLauncher =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"
      find "$apps" -maxdepth 1 -name 'alacritty*.desktop' \
        -exec grep -q '/nix/store/.*alacritty' {} \; -delete || true
      cat > "$apps/alacritty.desktop" <<EOF
[Desktop Entry]
Name=Alacritty
GenericName=Terminal
Exec=${alacrittyWrapped}/bin/alacritty
Icon=alacritty
Type=Application
Categories=System;TerminalEmulator;
Terminal=false
EOF
      ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
    '';

  ################################  icons  ###################################
  home.activation.installAlacrittyIcons =
    lib.hm.dag.entryAfter [ "installAlacrittyLauncher" ] ''
      ${copyAlacrittyIcons}/bin/copy-alacritty-icons
    '';

  ################################  packages  ################################
  home.packages = with pkgs; [
    # CLI
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron (wrapped)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode)  (lib.lowPrio pkgs.postman)

    # JetBrains IDEs
    jetbrains.datagrip
    jetbrains.rider

    # GUI apps
    emacs29-pgtk
    alacrittyWrapped
    google-chrome

    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ################################  shell / tools  ###########################
  programs.zsh.enable            = true;
  programs.zsh.oh-my-zsh.enable  = true;
  programs.zsh.oh-my-zsh.theme   = "agnoster";

  programs.tmux.enable           = true;
  programs.tmux.extraConfig = ''
    set -g mouse on
    set -g history-limit 100000
  '';

  programs.git = {
    enable    = true;
    userName  = "Rob";
    userEmail = "rob@example.com";
  };

  home.shellAliases = { k="kubectl"; dcu="docker compose up -d"; dcd="docker compose down"; };
  fonts.fontconfig.enable = true;

  ################################  ghostty terminfo  ########################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ################################  cloudflared  #############################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}