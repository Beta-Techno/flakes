{ pkgs, lib, ... }:

###############################################################################
#  rob’s Home-Manager module – minimal & working
###############################################################################

let
  # === Electron packages that need --no-sandbox wrappers ===
  vscode      = pkgs.vscode;
  postmanPkg  = pkgs.postman;
  dataGrip    = pkgs.jetbrains.datagrip;
  riderPkg    = pkgs.jetbrains.rider;

  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';
in
{
  # Make PATH & XDG_DATA_DIRS available to GNOME/KDE early
  targets.genericLinux.enable = true;

  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # ------------ Packages (CLI + GUI) ----------
  home.packages = with pkgs; [
    # CLI tools
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Wrappers (shadow originals, launch with --no-sandbox)
    (wrapElectron vscode     "code")
    (wrapElectron postmanPkg "postman")
    (wrapElectron dataGrip   "datagrip")
    (wrapElectron riderPkg   "rider")

    # Original GUI apps, low priority so file-name clashes disappear
    (lib.lowPrio vscode)
    (lib.lowPrio postmanPkg)
    (lib.lowPrio dataGrip)
    (lib.lowPrio riderPkg)

    emacs29-pgtk
    alacritty
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # ------------ Shell & tools  ----------------
  programs.zsh = {
    enable = true;
    oh-my-zsh.enable = true;
    oh-my-zsh.theme  = "agnoster";
  };

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
    k   = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };

  fonts.fontconfig.enable = true;

  # ------------ Ghostty terminfo --------------
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  # ------------ Cloudflared tunnel service ----
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