{ pkgs, lib, ... }:

###############################################################################
#  Rob’s Home-Manager module
#  • Adds GUI apps (Code, JetBrains, Chrome, Postman, Emacs GTK…)
#  • Makes them visible in Ubuntu’s launcher via targets.genericLinux
#  • Wraps Electron apps with --no-sandbox (works around /nix nosuid mount)
###############################################################################

let
  # Helper: create a tiny wrapper "<name>" that calls the real binary with
  # --no-sandbox so it works on non-NixOS systems where /nix is mounted nosuid.
  wrapElectron = appPkg: name:
    pkgs.writeShellScriptBin name ''
      exec ${appPkg}/bin/${name} --no-sandbox "$@"
    '';
in
{
  ## Export PATH / XDG_DATA_DIRS early via systemd → desktop search works
  targets.genericLinux.enable = true;

  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # ------------ Packages (CLI + GUI) ----------
  home.packages = with pkgs; [
    # --- CLI tools ---
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # --- GUI apps (original packages) ---
    vscode
    emacs29-pgtk
    alacritty
    jetbrains.datagrip
    jetbrains.rider
    google-chrome
    postman
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })

    # --- Electron wrappers (shadow originals in PATH) ---
    (wrapElectron vscode              "code")
    (wrapElectron postman             "postman")
    (wrapElectron jetbrains.datagrip  "datagrip")
    (wrapElectron jetbrains.rider     "rider")
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
  home.activation.installGhosttyTerminfo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

  # Let Home-Manager manage itself
  programs.home-manager.enable = true;
}