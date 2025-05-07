{ pkgs, unstable, lib, ... }:

###############################################################################
#  Rob’s Home-Manager module – Ubuntu desktop
#  * Electron apps wrapped with --no-sandbox
#  * JetBrains IDEs run natively
#  * Alacritty uses alacritty-fhs from unstable → fixes GL/Wayland crash
###############################################################################

let
  # Electron apps
  vscode     = pkgs.vscode;
  postmanPkg = pkgs.postman;

  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';
in
{
  # Make ~/.nix-profile visible to GNOME/KDE
  targets.genericLinux.enable = true;

  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # ------------ Packages ----------------------
  home.packages = with pkgs; [
    ## CLI tools
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    ## Electron (wrappers)
    (wrapElectron vscode     "code")
    (wrapElectron postmanPkg "postman")
    (lib.lowPrio vscode) (lib.lowPrio postmanPkg)

    ## JetBrains IDEs
    jetbrains.datagrip
    jetbrains.rider

    ## GUI apps
    emacs29-pgtk
    unstable.alacritty-fhs     # ← FHS build from unstable, works on Ubuntu
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # ------------ Shell & tools -----------------
  programs.zsh = {
    enable           = true;
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

  # ------------ Ghostty terminfo --------------
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  # ------------ Cloudflared tunnel ------------
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