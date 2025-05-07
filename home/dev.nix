{ pkgs, lib, ... }:

################################################################################
# Rob’s Home-Manager module – Ubuntu desktop
################################################################################

let
  # Electron packages we need to wrap
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
  ## Make PATH/XDG paths appear to the session early
  targets.genericLinux.enable = true;

  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  #################################
  # Packages
  #################################
  home.packages = with pkgs; [
    # CLI tools
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron wrappers (shadow originals)
    (wrapElectron vsCode     "code")
    (wrapElectron postmanPkg "postman")
    (wrapElectron dataGrip   "datagrip")
    (wrapElectron riderPkg   "rider")

    # Originals kept low-priority to avoid /bin clashes
    (lib.lowPrio vsCode)  (lib.lowPrio postmanPkg)
    (lib.lowPrio dataGrip) (lib.lowPrio riderPkg)

    # Other GUI apps
    emacs29-pgtk  alacritty  google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  #################################
  # Desktop-file symlinks & cache
  #################################
  home.activation.linkDesktopEntries =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      apps="$HOME/.local/share/applications"
      mkdir -p "$apps"

      # Remove any previous HM symlinks from earlier runs
      find "$apps" -xtype l -lname "$HOME/.nix-profile/*" -delete

      # Link every .desktop file from the Nix profile
      for f in "$HOME/.nix-profile/share/applications"/*.desktop; do
        ln -sf "$f" "$apps/$(basename "$f")"
      done

      # Rebuild MIME/desktop database so GNOME indexes them
      ${pkgs.desktop-file-utils}/bin/update-desktop-database "$apps" || true
    '';

  #################################
  # Shell, Git, Tmux (unchanged)
  #################################
  programs.zsh = {
    enable = true;
    oh-my-zsh.enable = true;
    oh-my-zsh.theme  = "agnoster";
  };

  programs.tmux = {
    enable       = true;
    extraConfig  = ''
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
    k   = "kubectl";
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

  # Cloudflared tunnel
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