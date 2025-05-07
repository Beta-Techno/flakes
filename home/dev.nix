# =============================
#  home/dev.nix  — single source of truth
# =============================
{ pkgs, ... }:
{
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # -----------------------------------------------------------
  # Packages (CLI + Nerd Font)
  # -----------------------------------------------------------
  home.packages = with pkgs; [
    tmux git ripgrep fd bat fzf jq htop inetutils
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