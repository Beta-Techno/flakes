{ config, pkgs, lib, helpers, ... }:

{
  home.packages = with pkgs; [
    (helpers.wrapElectron vscode "code")
    (lib.lowPrio vscode)  # icons / resources
  ];
} 