{ config, pkgs, lib, helpers, ... }:

{
  home.packages = with pkgs; [
    (helpers.wrapElectron pkgs.vscode "code")
    (lib.lowPrio pkgs.vscode)  # icons / resources
  ];
} 