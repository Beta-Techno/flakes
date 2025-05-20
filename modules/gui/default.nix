{ config, pkgs, lib, helpers, ... }:

{
  imports = [
    ./chrome.nix
    ./vscode.nix
    ./postman.nix
    ./jetbrains
    ./dock.nix
    ./fonts.nix
    ./theme.nix
  ];
} 