{ platform, pkgs, lib, ... }:

{
  # ── WSL-specific settings ──────────────────────────────────────
  home.packages = with pkgs; [
    # WSL utilities
    wslu
  ];
} 