{ config, pkgs, lib, helpers, ... }:

{
  home.packages = with pkgs; [
    (helpers.wrapElectron postman "postman")
    (lib.lowPrio postman)  # icons / resources
  ];
} 