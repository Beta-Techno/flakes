{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Network tools
    curl
    wget
    aria2
    rsync
    iftop
    tcpdump
    nmap
    wireshark
    traceroute
    mtr
    dig
    whois
  ];

  home.shellAliases = {
    # Network aliases
    myip = "curl -s https://api.ipify.org";
    ports = "sudo lsof -i -P -n | grep LISTEN";
  };
} 