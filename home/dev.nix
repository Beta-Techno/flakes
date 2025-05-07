{ config, pkgs, lib, ... }:

let
  nixBin = "${pkgs.nix}/bin/nix";

  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec ${nixBin} run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';
in
{
  # ── required identifiers ────────────────────────────────────────────────
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";
  targets.genericLinux.enable = true;

  # ── launcher pointing to wrapper ─────────────────────────────────────────
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

  # ── copy all icons, rename to lower-case, refresh cache ──────────────────
  home.activation.installAlacrittyIcons =
    lib.hm.dag.entryAfter [ "installAlacrittyLauncher" ] ''
      theme="$HOME/.local/share/icons/hicolor"
      shopt -s nullglob
      for file in ${pkgs.alacritty}/share/icons/hicolor/*/apps/*; do
        rel="$(echo "$file" | sed -E 's|.*?/hicolor/([^/]+/apps)/.*|\1|')"
        destDir="$theme/$rel"
        mkdir -p "$destDir"
        cp -f "$file" "$destDir/alacritty.${file##*.}"
      done
    '' + ''
      ${pkgs.gtk3}/bin/gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" || true
    '';

  # ── packages (unchanged) ────────────────────────────────────────────────
  home.packages = with pkgs; [
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode) (lib.lowPrio pkgs.postman)
    jetbrains.datagrip jetbrains.rider
    emacs29-pgtk
    alacrittyWrapped
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # ── shell / tools / extras (same as before) ──────────────────────────────
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

  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}