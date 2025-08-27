{ config, pkgs, lib, helpers, ... }:

{
  imports = 
    lib.optionals (pkgs.stdenv.isx86_64 || pkgs.stdenv.isDarwin) [ ./chrome.nix ] ++
    [ ./vscode.nix ./postman.nix ./jetbrains ./dock.nix ./fonts.nix ./theme.nix ];
} 