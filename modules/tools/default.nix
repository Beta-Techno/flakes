{ config, pkgs, lib, helpers, ... }:

{
  imports = [
    ./docker.nix
    ./kubernetes.nix
    ./cloudflared.nix
    ./git.nix
    ./system-tools.nix
    ./network-tools.nix
    ./tmux.nix
  ];

  home.packages = with pkgs; [
    # Modern replacements for common tools
    eza  # Modern ls
    bat  # Modern cat
    fd   # Modern find
    ripgrep  # Modern grep
    fzf  # Fuzzy finder
  ];
} 