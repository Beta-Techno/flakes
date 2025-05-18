{ config, pkgs, lib, username, doomConfig, ... }:

################################################################################
# Helpers
################################################################################
let
  nixBin = "${pkgs.nix}/bin/nix";

  # ── Common Electron wrapper (keeps namespace sandbox) ──────────────────────
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --disable-setuid-sandbox "$@"
    '';

  # ── Chrome wrapper (uses installed SUID helper) ────────────────
  chromeWrapped = pkgs.writeShellScriptBin "google-chrome" ''
    exec ${pkgs.google-chrome}/bin/google-chrome-stable \
         --sandbox-executable=/usr/local/bin/chrome-sandbox "$@"
  '';

  alacrittySvg =
    "${pkgs.alacritty}/share/icons/hicolor/scalable/apps/Alacritty.svg";
in
################################################################################
# Configuration
################################################################################
{
  ############################  Basics  #######################################
  home.stateVersion  = "24.05";
  home.username = username;
  home.homeDirectory = "/home/${username}";

  ############################  Chrome launcher  ##############################
  home.activation.installChromeLauncher =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"
      cat > "$apps/google-chrome.desktop" <<EOF
[Desktop Entry]
Name=Google Chrome
Exec=${chromeWrapped}/bin/google-chrome %U
Icon=google-chrome
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF
      ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
    '';

  ############################  Packages  #####################################
  home.packages = with pkgs; [
    # CLI
    git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron GUI (sandbox preserved)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode)   # icons / resources
    (lib.lowPrio pkgs.postman)

    # JetBrains
    jetbrains.datagrip
    jetbrains.rider

    # Other GUI
    chromeWrapped
    (lib.lowPrio pkgs.google-chrome)

    # Fonts
    nerd-fonts.jetbrains-mono
  ];

  ############################  Shell / tools  ################################
  programs.zsh.enable           = true;
  programs.zsh.oh-my-zsh.enable = true;
  programs.zsh.oh-my-zsh.theme  = "agnoster";

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

  ############################  Ghostty terminfo  #############################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ############################  Cloudflared  ##################################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;

  ############################  Dock / sidebar  ###############################
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "alacritty.desktop"
        "org.gnome.Terminal.desktop"
        "emacs.desktop"
        "google-chrome.desktop"
        "code.desktop"
        "rider.desktop"
        "datagrip.desktop"
        "postman.desktop"
      ];
    };
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      autohide      = false;
    };
    "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
  };

  ############################  Doom Emacs  ###################################
  programs.doom-emacs = {
    enable = true;
    doomDir = doomConfig;
    emacs = pkgs.emacs30-pgtk;
    doomLocalDir = "/home/${username}/.local/share/doom";
  };
} 