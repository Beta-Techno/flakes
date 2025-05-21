{ config, pkgs, lib, helpers, ... }:

{
  home.packages = with pkgs; [
    (helpers.mkChromiumWrapper { pkg = vscode; exe = "code"; })
    (lib.lowPrio vscode)  # icons / resources
  ];
} 