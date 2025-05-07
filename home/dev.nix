-- home/dev.nix ------------------------------------------------------------
{ pkgs, lib, config, ... }:

###############################################################################
#  Rob’s Home-Manager module  – Ubuntu 24 · Intel Iris 6100
#  • Electron apps wrapped with --no-sandbox
#  • JetBrains IDEs run natively
#  • Alacritty launched through nixGLIntel
#  • Single launcher icon that works (uses absolute /nix/store path to `nix`)
###############################################################################

let
  # ── absolute path to the Nix CLI (so GNOME launcher doesn’t need $PATH) ──
  nixBin = "${pkgs.nix}/bin/nix";

  # ── helper: wrap an Electron app with --no-sandbox ────────────────────────
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # ── helper: Alacritty wrapper → nixGLIntel ───────────────────────────────
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec ${nixBin} run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  # Icon for the launcher
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

  home.activation.installAlacrittyDesktop =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"

      # Remove any old launchers that call the store binary
      find "$apps" -maxdepth 1 -type f -name 'alacritty*.desktop' \
           -exec grep -q '/nix/store/.*alacritty' {} \; -delete || true

      # Install our launcher that calls the wrapper directly
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

      ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
    '';

  ##########################  Packages  ######################################
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

    # GUI apps
    emacs29-pgtk
    alacrittyWrapped                 # wrapper binary
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