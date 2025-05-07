{ pkgs, lib, ... }:

###############################################################################
#  Rob’s Home-Manager module  – Ubuntu laptop (Intel Iris 6100)
###############################################################################

let
  # ---------- helpers -------------------------------------------------------

  # Wrap an Electron app with --no-sandbox
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # Wrap Alacritty so it runs through nixGLIntel
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec nix run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  alacrittyIcon = "${pkgs.alacritty}/share/icons/hicolor/512x512/apps/Alacritty.png";
in
{
  ##########  Desktop integration ############################################
  targets.genericLinux.enable = true;

  # Write a fresh launcher that points to the wrapper and hides any old one
  home.activation.installAlacrittyDesktop =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"

      # Remove stale Alacritty launchers that call the store binary
      find "$apps" -maxdepth 1 -type f -name 'alacritty*.desktop' \
           -exec grep -q '/nix/store/.*alacritty' {} \; -delete || true

      # Write the new desktop entry
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

      # Refresh desktop database so GNOME sees the change immediately
      ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
    '';

  ##########  Basic home info #################################################
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  ##########  Packages #######################################################
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

    # GUI apps
    emacs29-pgtk
    alacrittyWrapped             # wrapper binary
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ##########  Shell, Git, Tmux ###############################################
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

  ##########  Ghostty terminfo ###############################################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ##########  Cloudflared tunnel (user scope) ################################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}