{ config, pkgs, lib, ... }:

{
  # ── Docker configuration ───────────────────────────────────────
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  # ── Docker Compose ────────────────────────────────────────────
  home.packages = with pkgs; [
    docker-compose
  ];

  # ── Docker shell integration ──────────────────────────────────
  programs.zsh.initExtra = ''
    # Docker shell integration
    if [ -f /usr/share/zsh/site-functions/_docker ]; then
      source /usr/share/zsh/site-functions/_docker
    fi
  '';
} 