{ config, pkgs, lib, ... }:

let
  helpers = import ../lib/helpers.nix { inherit pkgs lib; };
in
{
  imports = [
    ./chrome.nix
    ./vscode.nix
    ./postman.nix
    ./jetbrains
    ./dock.nix
    ./fonts.nix
  ];

  _module.args = {
    inherit helpers;
  };
} 