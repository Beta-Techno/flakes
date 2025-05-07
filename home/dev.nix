# =============================
#  home/dev.nix  — incremental package rollout
# =============================
{ pkgs, ... }:
{
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # -----------------------------------------------------------
  # Packages — PHASE 1: core dev + network tools
  # We'll add GUI apps, JetBrains, etc. in later phases.
  # -----------------------------------------------------------
  home.packages = with pkgs; [
    # ── CLI fundamentals ─────────────────────────────
    tmux git ripgrep fd bat fzf jq htop inetutils

    # ── Dev / build chain ────────────────────────────
    neovim nodejs_20 docker-compose kubectl

    # ── Fonts ────────────────────────────────────────
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

    # ──────────────────────────────────────────────────────────
  # Ghostty terminfo so programs recognise $TERM=xterm-ghostty
  # ──────────────────────────────────────────────────────────
    # ──────────────────────────────────────────────────────────
  # Ghostty terminfo so programs recognise $TERM=xterm-ghostty
  # ──────────────────────────────────────────────────────────
  home.file.".terminfo/x/xterm-ghostty".source = builtins.fetchurl {
    url    = "https://raw.githubusercontent.com/ghostty-org/ghostty/main/data/xterm-ghostty.terminfo";
    sha256 = "sha256-4OmAqRmwYj1R7zoqU3i++PtFAVwsfl5b7/5uPT1Y99U=";
  }; = "sha256-Pjg9My54wWk2c5O2qAi6qkQyB+Hovk4p6YclM+FGgsc=";
    };


  # -----------------------------------------------------------
  # Services
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