{ pkgs
, lib
, config
, ...
}:

###############################################################################
#  Rob’s Home-Manager module  – Ubuntu laptop (Intel Iris 6100)
#  • Electron apps wrapped with --no-sandbox
#  • JetBrains IDEs run natively
#  • Alacritty launched through nixGLIntel (works with Mesa)
#  • A single launcher icon that calls the working wrapper
###############################################################################

let
  # ───────── helpers ─────────────────────────────────────────────────────────

  # Wrap any Electron app with --no-sandbox
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # Alacritty wrapper that runs through nixGLIntel
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec nix run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  # Absolute icon path
  alacrittyIcon = "${pkgs.alacritty}/share/icons/hicolor/512x512/apps/Alacritty.png";

  # Custom launcher text
  alacrittyDesktop = pkgs.writeText "alacritty.desktop" ''
    [Desktop Entry]
    Name=Alacritty
    GenericName=Terminal
    Exec=sh -c "${alacrittyWrapped}/bin/alacritty"
    Icon=${alacrittyIcon}
    Type=Application
    Categories=System;TerminalEmulator;
    Terminal=false
  '';
in
{
  ##############################  Desktop ####################################
  targets.genericLinux.enable = true;

  # Copy our launcher & hide the stock one
  home.activation.fixAlacrittyDesktop =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"

      # Remove any Alacritty launchers that run the store binary
      find "$apps" -maxdepth 1 -type f -name 'alacritty*.desktop' \
           -exec grep -q '/nix/store/.*alacritty' {} \; -delete || true

      # Install our wrapper-based launcher
      cp -f "${alacrittyDesktop}" "$apps/alacritty.desktop"

      # Refresh desktop database
      ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
    '';

  ##############################  Home info ##################################
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  ##############################  Packages ###################################
  home.packages = with pkgs; [
    # CLI tools
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron (wrapped)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode) (lib.lowPrio pkgs.postman)

    # JetBrains IDEs
    jetbrains.datagrip
    jetbrains.rider

    # GUI
    emacs29-pgtk
    alacrittyWrapped                 # wrapper binary
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ##############################  Shell / tools ##############################
  programs.zsh = {
    enable            = true;
    oh-my-zsh.enable  = true;
    oh-my-zsh.theme   = "agnoster";
  };

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
    k   = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };

  fonts.fontconfig.enable = true;

  ##############################  Ghostty terminfo ###########################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ##############################  Cloudflared ###############################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}