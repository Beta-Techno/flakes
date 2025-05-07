{ pkgs, lib, ... }:

###############################################################################
#  Rob’s Home-Manager module  (Ubuntu laptop, Intel Iris 6100)
###############################################################################

let
  ### helpers #################################################################
  # Electron wrapper
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # Alacritty wrapper → nixGLIntel
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec nix run --impure github:guibou/nixGL#nixGLIntel -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  alacrittyIcon = "${pkgs.alacritty}/share/icons/hicolor/512x512/apps/Alacritty.png";
in
{
  targets.genericLinux.enable = true;

  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  ###################### fresh .desktop entry #################################
  xdg.desktopEntries.alacritty = {
    name        = "Alacritty";
    genericName = "Terminal";
    exec        = "${alacrittyWrapped}/bin/alacritty";
    icon        = alacrittyIcon;
    type        = "Application";
    categories  = [ "System" "TerminalEmulator" ];
    terminal    = false;
  };

  ### remove stale launchers & refresh cache each switch ######################
  home.activation.fixAlacrittyDesktop = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    apps="$HOME/.local/share/applications"
    mkdir -p "$apps"

    # delete any old Alacritty launchers linking into the store
    find "$apps" -maxdepth 1 -type f -name 'alacritty*.desktop' \
         -exec grep -q "$HOME/.nix-profile" {} \; -o -delete

    # copy the freshly generated desktop file
    cp -f "${config.xdg.desktopEntries.alacritty.desktopFile}" "$apps/alacritty.desktop"

    # update MIME/desktop cache so GNOME picks it up immediately
    ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
  '';

  ###################### packages #############################################
  home.packages = with pkgs; [
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode) (lib.lowPrio pkgs.postman)

    jetbrains.datagrip jetbrains.rider
    emacs29-pgtk
    alacrittyWrapped
    (lib.lowPrio pkgs.alacritty)
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ###################### shell / misc (unchanged) #############################
  programs.zsh.enable = true;
  programs.zsh.oh-my-zsh.enable = true;
  programs.zsh.oh-my-zsh.theme = "agnoster";

  programs.tmux.enable = true;
  programs.tmux.extraConfig = ''
    set -g mouse on
    set -g history-limit 100000
  '';

  programs.git.enable    = true;
  programs.git.userName  = "Rob";
  programs.git.userEmail = "rob@example.com";

  home.shellAliases = {
    k = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };

  fonts.fontconfig.enable = true;

  ### ghostty terminfo / cloudflared service blocks unchanged … ###############
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
    Service.Restart = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}