{ pkgs, lib, ... }:

############################################
# Rob’s Home-Manager module for Ubuntu
############################################
let
  # Original GUI packages
  vsCode     = pkgs.vscode;
  postmanPkg = pkgs.postman;
  dataGrip   = pkgs.jetbrains.datagrip;
  riderPkg   = pkgs.jetbrains.rider;

  # Wrap an Electron binary with --no-sandbox.
  wrapElectron = appPkg: exeName:
    pkgs.writeShellScriptBin exeName ''
      exec ${appPkg}/bin/${exeName} --no-sandbox "$@"
    '';
in
{
  ## Export PATH / XDG_DATA_DIRS early so GNOME sees .desktop files
  targets.genericLinux.enable = true;

  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # ------------ Packages (CLI + GUI) ----------
  home.packages = with pkgs; [
    # --- CLI tools ---
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # --- Wrappers (take precedence in PATH) ---
    (wrapElectron vsCode     "code")
    (wrapElectron postmanPkg "postman")
    (wrapElectron dataGrip   "datagrip")
    (wrapElectron riderPkg   "rider")

    # --- Original GUI apps, but low priority so /bin collision is skipped ---
    (lib.lowPrio vsCode)
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

  # ------------ Services ----------------------
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
      Restart   = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}