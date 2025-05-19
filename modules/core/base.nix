{ config, pkgs, lib, username, ... }:

{
  # ── Basic configuration ──────────────────────────────────────────
  home.stateVersion = "24.05";
  home.username = username;
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";

  # ── Font configuration ───────────────────────────────────────────
  fonts.fontconfig.enable = true;

  # ── Home Manager ────────────────────────────────────────────────
  programs.home-manager.enable = true;

  # ── Shell configuration ─────────────────────────────────────────
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
    };
  };

  # ── Common shell aliases ────────────────────────────────────────
  home.shellAliases = {
    k = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };
} 