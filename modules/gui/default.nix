{ config, pkgs, lib, helpers, ... }:

{
  imports = [ ./vscode.nix ./postman.nix ./jetbrains ./dock.nix ./fonts.nix ./theme.nix ./chrome.nix ];
} 