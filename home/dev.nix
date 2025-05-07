# =============================
#  home/dev.nix
# =============================
{ pkgs, ... }:
{
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # -----------------------------------------------------------
  # Packages
  # -----------------------------------------------------------
  home.packages = with pkgs; [
    tmux git ripgrep fd bat fzf jq htop inetutils
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # -----------------------------------------------------------
  # Shell & editor tooling
  # -----------------------------------------------------------
  programs.zsh = {
    enable       = true;
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
  # Cloudflare tunnel (user‑level service)
  # -----------------------------------------------------------
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

# =============================
{ pkgs, ... }:
{
  # -------------------------------------------------------------
  # Core user metadata
  # -------------------------------------------------------------
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";   # DO NOT change until you upgrade nixpkgs

  # -------------------------------------------------------------
  # Packages (CLI + fonts)
  # -------------------------------------------------------------
  home.packages = with pkgs; [
    # CLI utilities
    tmux git ripgrep fd bat fzf jq htop inetutils

    # Fonts (JetBrainsMono Nerd Font + others)
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # -------------------------------------------------------------
  # Z‑shell with Oh‑My‑Zsh
  # -------------------------------------------------------------
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme  = "agnoster";
    };
  };

  # -------------------------------------------------------------
  # Tmux configuration
  # -------------------------------------------------------------
  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g mouse on
      set -g history-limit 100000
    '';
  };

  # -------------------------------------------------------------
  # Git defaults
  # -------------------------------------------------------------
  programs.git = {
    enable    = true;
    userName  = "Rob";
    userEmail = "rob@example.com";
  };

  # -------------------------------------------------------------
  # Handy aliases
  # -------------------------------------------------------------
  home.shellAliases = {
    k   = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };

  # -------------------------------------------------------------
  # Fontconfig so the Nerd Font is picked up by GUI apps
  # -------------------------------------------------------------
  fonts.fontconfig.enable = true;

  # -------------------------------------------------------------
  # User‑level systemd service example: Cloudflare Tunnel
  # -------------------------------------------------------------
  systemd.user.services.cloudflared = {
    Unit = {
      Description = "Cloudflare Tunnel (user scope)";
      After       = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
      Restart   = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Let Home‑Manager manage itself so upgrades are declarative
  programs.home-manager.enable = true;
}