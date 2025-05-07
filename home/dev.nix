###############################################################################
#  home/dev.nix — Rob’s Home-Manager profile  (Ubuntu 24 · Intel Iris 6100)
###############################################################################
{ config, pkgs, lib, ... }:

################################################################################
# Helpers
################################################################################
let
  nixBin = "${pkgs.nix}/bin/nix";

  # 1. Wrap Electron app with --no-sandbox
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # 2. Alacritty wrapper → nixGLIntel
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec ${nixBin} run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  # 3. Script: copy every icon & rename to lower-case “alacritty.*”
  copyAlacrittyIcons = pkgs.writeShellApplication {
    name = "copy-alacritty-icons";
    runtimeInputs = [ pkgs.gtk3 ];
    text = ''
      set -eu
      theme="$HOME/.local/share/icons/hicolor"
      find '${pkgs.alacritty}/share/icons/hicolor' -type f -name '*[Aa]lacritty.*' | \
      while read -r file; do
        size=$(echo "$file" | sed -E 's|.*/hicolor/([^/]+)/apps/.*|\1|')   # 512x512 or scalable
        dest="$theme/$size/apps"
        mkdir -p "$dest"
        ext=$(printf '%s\n' "$file" | awk -F. '{print $NF}')
        cp -f "$file" "$dest/alacritty.$ext"
      done
      gtk-update-icon-cache "$theme" || true
    '';
  };
in
################################################################################
# Home-Manager configuration
################################################################################
{
  ### Required
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  targets.genericLinux.enable = true;   # make ~/.nix-profile visible to GNOME

  ### 1. Launcher
  home.activation.installAlacrittyLauncher =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"
      # drop stale launchers pointing inside /nix/store
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

  ### 2. Icons
  home.activation.installAlacrittyIcons =
    lib.hm.dag.entryAfter [ "installAlacrittyLauncher" ] ''
      ${copyAlacrittyIcons}/bin/copy-alacritty-icons
    '';

  ### Packages
  home.packages = with pkgs; [
    # CLI
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron (wrapped)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode)  (lib.lowPrio pkgs.postman)

    # JetBrains IDEs
    jetbrains.datagrip jetbrains.rider

    # GUI apps
    emacs29-pgtk
    alacrittyWrapped
    google-chrome

    # Fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ### Shell / tools
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
    k="kubectl"; dcu="docker compose up -d"; dcd="docker compose down";
  };

  fonts.fontconfig.enable = true;

  ### Ghostty terminfo
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ### Cloudflared tunnel
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}