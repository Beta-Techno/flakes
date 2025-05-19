{ config, pkgs, lib, helpers, ... }:

{
  home.packages = with pkgs; [
    (helpers.wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.postman)  # icons / resources
  ];
} 