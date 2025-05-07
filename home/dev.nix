###############################################################################
#  home/dev.nix — Rob’s Home-Manager profile (Ubuntu 24, Intel Iris 6100)
#  • GUI apps via nix on Ubuntu
#  • Alacritty wrapped with nixGLIntel and a working launcher + icon
###############################################################################
{ config, pkgs, lib, ... }:

let
  # Absolute path to the Nix CLI so GNOME doesn’t depend on $PATH
  nixBin = "${pkgs.nix}/bin/nix";

  # ── helpers ────────────────────────────────────────────────────────────────

  # Wrap an Electron app with --no-sandbox
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # Alacritty wrapper → nixGLIntel
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec ${nixBin} run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  # Icon shipped inside the Alacritty package
  alacrittyIcon =
    "${pkgs.alacritty}/share/icons/hicolor/512x512/apps/Alacritty.png";
in
{
  ##########################  REQUIRED identifiers  ##########################
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  ##########################  Desktop integration  ###########################
  targets.genericLinux.enable = true;

  # 1) Install a launcher that points to the wrapper
  home.activation.installAlacrittyDesktop =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"

      # Remove old launchers pointing to the store binary
      find "$apps" -maxdepth 1 -type f -name 'alacritty*.desktop' \
           -exec grep -q '/nix/store/.*alacritty' {} \; -delete || true

      # Write our launcher (Icon=alacritty — picks user-theme icon)
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

  # 2) Copy icon into the user icon theme & refresh cache
  home.activation.installAlacrittyIcon =
    lib.hm.dag.entryAfter [ "installAlacrittyDesktop" ] ''
      iconDir="$HOME/.local/share/icons/hicolor/512x512/apps"
      mkdir -p "$iconDir"
      cp -f ${alacrittyIcon} "$iconDir/alacritty.png"
      ${pkgs.gtk3}/bin/gtk-update-icon-cache \
        "$HOME/.local/share/icons/hicolor" || true
    '';

  ##########################  Packages  ######################################
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
    alacrittyWrapped
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ##########################  Shell / tools  #################################
  programs.zsh = {
    enable            = true;
    oh-my-zsh.enable  = true;
    oh-my-zsh.theme   = "agnoster";
  };

  programs.tmux = {
    enable       = true;
    extraConfig  = ''
      set -g mouse on
      set -g history-limit 100000
    '';
  };

  programs.git = {
    enable     = true;
    userName   = "Rob";
    userEmail  = "rob@example.com";
  };

  home.shellAliases = {
    k   = "kubectl";
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

  ##########################  Cloudflared tunnel  ############################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}