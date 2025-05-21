{ config, pkgs, lib, helpers, ... }:

{
  home.packages = with pkgs; [
    (helpers.mkChromiumWrapper { pkg = postman; exe = "postman"; })
    (lib.lowPrio postman)  # icons / resources
  ];
} 