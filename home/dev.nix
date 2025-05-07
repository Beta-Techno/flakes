# =============================
#  home/dev.nix — incremental package rollout
# =============================
{ pkgs, lib, ... }:
{
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # -----------------------------------------------------------
  # Packages — PHASE 1: core dev + network tools
  # -----------------------------------------------------------
  home.packages = with pkgs; [
    # CLI fundamentals
    tmux git ripgrep fd bat fzf jq htop inetutils

    # Dev / build chain
    neovim nodejs_20 docker-compose kubectl

    # Fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # -----------------------------------------------------------
  # Shell & editor tooling
  # -----------------------------------------------------------
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

  # -----------------------------------------------------------
  # Ghostty terminfo — compile at activation time (robust, offline)
  # -----------------------------------------------------------
  # 1. Source file lives one directory up from home/ (../terminfo)
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;

  # 2. Compile into ~/.terminfo on every switch so xterm-ghostty is found
  home.activation.installGhosttyTerminfo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.terminfo"
    tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
  '';


  # -----------------------------------------------------------
  # Ghostty terminfo — compile at activation time (robust, no 404)
  # -----------------------------------------------------------
  # 1.  Store source in flake (text file committed in ./terminfo)
    # dev.nix lives in ./home, terminfo file is one level up
    home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
}