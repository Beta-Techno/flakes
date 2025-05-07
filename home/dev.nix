{ pkgs, lib, config, ... }:

###############################################################################
#  Rob’s Home-Manager module – Ubuntu 24 · Intel Iris 6100 (nixGLIntel)
###############################################################################

let
  # ---------- helpers -------------------------------------------------------

  # Wrap Electron apps with --no-sandbox
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # Wrap Alacritty so it runs through nixGLIntel
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec nix run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  # Icon path
  alacrittyIcon =
    "${pkgs.alacritty}/share/icons/hicolor/512x512/apps/Alacritty.png";
in
{
  ##############################  REQUIRED  ##################################
  home.stateVersion = "24.05";

  ##############################  Desktop ####################################
  targets.genericLinux.enable = true;

  home.activation.installAlacrittyDesktop =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"

      # Remove any old launchers that point to the store binary
      find "$apps" -maxdepth 1 -type f -name 'alacritty*.desktop' \
           -exec grep -q '/nix/store/.*alacritty' {} \; -delete || true

      # Write our launcher that calls the wrapper directly
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

      # Update cache so GNOME sees it immediately
      ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
    '';

  ##############################  Packages ###################################
  home.packages = with pkgs; [
    # CLI
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron (wrapped)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode)  (lib.lowPrio pkgs.postman)

    # JetBrains
    jetbrains.datagrip
    jetbrains.rider

    # GUI
    emacs29-pgtk
    alacrittyWrapped
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ##############################  Shell / tools ##############################
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

  home.shellAliases = { k = "kubectl"; dcu = "docker compose up -d"; dcd = "docker compose down"; };
  fonts.fontconfig.enable = true;

  ##############################  Ghostty terminfo ###########################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ##############################  Cloudflared ################################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}