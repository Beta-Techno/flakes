{ config, pkgs, lib, ... }:

################################################################################
#  Rob’s Home-Manager profile – Ubuntu 24 / Intel Iris 6100
#  · Alacritty via nixGLIntel with working launcher & icons
#  · Electron apps wrapped with --no-sandbox
#  · JetBrains IDEs and other GUI apps
################################################################################

let
  nixBin = "${pkgs.nix}/bin/nix";   # absolute path for Exec=

  # ---------- helpers -------------------------------------------------------
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec ${nixBin} run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  icons512 = "${pkgs.alacritty}/share/icons/hicolor/512x512/apps/Alacritty.png";
  icons128 = "${pkgs.alacritty}/share/icons/hicolor/128x128/apps/Alacritty.png";
in
{
  ##########################  Essentials  ####################################
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";
  targets.genericLinux.enable = true;

  ##########################  Launcher + icons ###############################
  home.activation.installAlacrittyLauncher =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"

      # wipe stock launchers that call the store binary
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

  home.activation.installAlacrittyIcons =
    lib.hm.dag.entryAfter [ "installAlacrittyLauncher" ] ''
      theme="$HOME/.local/share/icons/hicolor"
      mkdir -p "$theme/512x512/apps" "$theme/128x128/apps"

      cp -f ${icons512} "$theme/512x512/apps/alacritty.png"
      cp -f ${icons128} "$theme/128x128/apps/alacritty.png"

      ${pkgs.gtk3}/bin/gtk-update-icon-cache "$theme" || true
    '';

  ##########################  Packages  ######################################
  home.packages = with pkgs; [
    ## CLI
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    ## Electron (wrapped)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode) (lib.lowPrio pkgs.postman)

    ## JetBrains IDEs
    jetbrains.datagrip
    jetbrains.rider

    ## GUI
    emacs29-pgtk
    alacrittyWrapped
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ##########################  Shell / tools  #################################
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
    k = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };

  fonts.fontconfig.enable = true;

  ##########################  Ghostty terminfo  ##############################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ##########################  Cloudflared ####################################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}