###############################################################################
#  home/dev.nix — Rob's Home-Manager profile  (Ubuntu 24 · Intel Iris 6100)
###############################################################################
{ config, pkgs, lib, ... }:

################################################################################
# Helpers
################################################################################
let
  nixBin = "${pkgs.nix}/bin/nix";

  # ── Electron wrapper ───────────────────────────────────────────────────────
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # ── Chrome wrapper ────────────────────────────────────────────────────────
  chromeWrapped = pkgs.writeShellScriptBin "google-chrome" ''
    exec ${pkgs.google-chrome}/bin/google-chrome-stable --no-sandbox "$@"
  '';

  # ── Alacritty wrapper → nixGLIntel ─────────────────────────────────────────
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec ${nixBin} run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  # ── Only icon shipped by Alacritty in current nixpkgs ──────────────────────
  alacrittySvg =
    "${pkgs.alacritty}/share/icons/hicolor/scalable/apps/Alacritty.svg";
in
################################################################################
# Configuration
################################################################################
{
  ##############################  Basics  #####################################
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";
  targets.genericLinux.enable = true;

  ##############################  Launcher  ###################################
  home.activation.installAlacrittyLauncher =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"
      rm -f "$apps/alacritty.desktop"

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

  ##############################  Icon  #######################################
  home.activation.installAlacrittyIcon =
    lib.hm.dag.entryAfter [ "installAlacrittyLauncher" ] ''
      theme="$HOME/.local/share/icons/hicolor/scalable/apps"
      mkdir -p "$theme"
      cp -f ${alacrittySvg} "$theme/alacritty.svg"
      ${pkgs.gtk3}/bin/gtk-update-icon-cache \
        "$HOME/.local/share/icons/hicolor" || true
    '';

  ##############################  Packages  ###################################
  home.packages = with pkgs; [
    # CLI tools
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron apps (wrapped)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode) (lib.lowPrio pkgs.postman)

    # JetBrains IDEs
    jetbrains.datagrip
    jetbrains.rider

    # Other GUI apps
    emacs29-pgtk
    alacrittyWrapped
    chromeWrapped
    (lib.lowPrio pkgs.google-chrome)  # original package, low-prio to avoid clash

    # Fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ##############################  Shell / tools  ##############################
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

  ##############################  Ghostty terminfo  ###########################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ##############################  Cloudflared  ################################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;

  ##############################  Dock / sidebar  #############################
  dconf.enable = true;

  dconf.settings = {
    # Ordered list of favorites (Dash-to-Dock reads this key)
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"  # Files
        "alacritty.desktop"           # Alacritty (our launcher)
        "org.gnome.Terminal.desktop"  # GNOME Terminal
        "emacs.desktop"               # Emacs GUI
        "google-chrome.desktop"       # Chrome
        "code.desktop"                # VS Code
        "rider.desktop"               # Rider (nixpkgs name)
        "datagrip.desktop"            # DataGrip (nixpkgs name)
        "postman.desktop"             # Postman
      ];
    };

    # Dash-to-Dock tweaks (left position is Ubuntu default)
    "org/gnome/shell/extensions/dash-to-dock" = {
      dash-max-icon-size = 32;   # px
      dock-position      = "LEFT";
      autohide           = false;
    };

    # Tell GNOME to prefer dark variants everywhere
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";   # 'default' | 'prefer-dark'
    };
  };
}