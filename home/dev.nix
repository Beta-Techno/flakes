###############################################################################
#  home/dev.nix — Rob’s Home-Manager profile (Ubuntu 24, Intel Iris 6100)
###############################################################################
{ config, pkgs, lib, ... }:

let
  ### helpers #################################################################

  nixBin = "${pkgs.nix}/bin/nix";          # absolute Nix CLI path

  # Wrap Electron app with --no-sandbox
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # Alacritty wrapper → nixGLIntel
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec ${nixBin} run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';
in
{
  ##################### Required identifiers ##################################
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  ##################### Desktop integration ###################################
  targets.genericLinux.enable = true;

  # 1️⃣  Launcher pointing to the wrapper
  home.activation.installAlacrittyDesktop =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"

      # remove old launchers that point to the store binary
      find "$apps" -maxdepth 1 -type f -name 'alacritty*.desktop' \
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

  # 2️⃣  Install all icons from the Alacritty package into the user theme
  home.activation.installAlacrittyIcon =
    lib.hm.dag.entryAfter [ "installAlacrittyDesktop" ] ''
      theme="$HOME/.local/share/icons/hicolor"
      for icon in ${pkgs.alacritty}/share/icons/hicolor/*/apps/Alacritty.*; do
        sizeDir="$(dirname "$(dirname "$icon")")"          # e.g. 512x512 or scalable
        baseSize="$(basename "$sizeDir")"
        dest="$theme/$baseSize/apps"
        mkdir -p "$dest"
        cp -f "$icon" "$dest/alacritty.${icon##*.}"
      done
      ${pkgs.gtk3}/bin/gtk-update-icon-cache "$theme" || true
    '';

  ##################### Packages ##############################################
  home.packages = with pkgs; [
    # CLI tools
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron apps (wrapped)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode) (lib.lowPrio pkgs.postman)

    # JetBrains
    jetbrains.datagrip
    jetbrains.rider

    # GUI
    emacs29-pgtk
    alacrittyWrapped                 # wrapper binary
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ##################### Shell / tools #########################################
  programs.zsh.enable            = true;
  programs.zsh.oh-my-zsh.enable  = true;
  programs.zsh.oh-my-zsh.theme   = "agnoster";

  programs.tmux.enable = true;
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
    k   = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };

  fonts.fontconfig.enable = true;

  ##################### Ghostty terminfo ######################################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ##################### Cloudflared tunnel ####################################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}