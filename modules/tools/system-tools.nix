{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Development utilities
    ripgrep
    fd
    bat
    fzf
    jq
    htop
    inetutils

    # System utilities
    pciutils
    usbutils
    lshw
    psmisc
    procps
    sysstat
    iotop

    # Archive tools
    zip
    unzip
    p7zip
    gzip
    gnutar

    # JetBrains tools
    jetbrains.datagrip
    jetbrains.rider
  ];

  home.shellAliases = {
    # System aliases
    df = "df -h";
    du = "du -h";
    free = "free -h";
    top = "htop";
  };
} 