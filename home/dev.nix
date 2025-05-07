{ pkgs, lib, ... }:

let
  # Original Electron packages
  vsCode     = pkgs.vscode;
  postmanPkg = pkgs.postman;
  dataGrip   = pkgs.jetbrains.datagrip;
  riderPkg   = pkgs.jetbrains.rider;

  # Wrapper generator (adds --no-sandbox)
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';
in
{
  targets.genericLinux.enable = true;

  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  ######################################
  ## Packages
  ######################################
  home.packages = with pkgs; [
    # CLI
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # GUI wrappers (first in $PATH)
    (wrapElectron vsCode     "code")
    (wrapElectron postmanPkg "postman")
    (wrapElectron dataGrip   "datagrip")
    (wrapElectron riderPkg   "rider")

    # GUI originals (low-priority to avoid /bin clashes)
    (lib.lowPrio vsCode) (lib.lowPrio postmanPkg)
    (lib.lowPrio dataGrip) (lib.lowPrio riderPkg)

    emacs29-pgtk alacritty google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ######################################
  ## Desktop-file symlinks & database
  ######################################
  home.activation.linkDesktopEntries =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dest="$HOME/.local/share/applications/home-manager"
      rm -rf "$dest"
      mkdir -p "$dest"
      for f in "$HOME/.nix-profile/share/applications"/*.desktop; do
        ln -sf "$f" "$dest/$(basename "$f")"
      done
      # rebuild MIME cache where GNOME can write
      ${pkgs.desktop-file-utils}/bin/update-desktop-database \
        "$HOME/.local/share/applications"
    '';

  ######################################
  ## Shell, git, tmux … (unchanged)
  ######################################
  programs.zsh.enable           = true;
  programs.zsh.oh-my-zsh.enable = true;
  programs.zsh.oh-my-zsh.theme  = "agnoster";

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g mouse on
      set -g history-limit 100000
    '';
  };

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

  # Ghostty terminfo
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  # Cloudflared user service
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service = {
      ExecStart =
        "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}