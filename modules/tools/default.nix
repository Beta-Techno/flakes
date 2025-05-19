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

  _module.args = {
    inherit helpers;
  };
} 