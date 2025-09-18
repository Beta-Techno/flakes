{ config, pkgs, lib, ... }:

let
  tftpRoot = "/srv/tftp";
  httpRoot = "/srv/pxe";
in
{
  imports = [
    ../profiles/base.nix
    ../profiles/nginx.nix
  ];

  system.stateVersion = "24.11";

  # Create directories for TFTP and HTTP assets
  systemd.tmpfiles.rules = [
    "d ${tftpRoot} 0755 root root -"
    "d ${httpRoot}/ipxe 0755 root root -"
  ];

  # --- NGINX: serve iPXE scripts at http://pxe.local/ipxe/ ---
  services.nginx.virtualHosts."pxe.local" = {
    root = httpRoot;
    # publish the scripts managed by Nix under /etc
    locations."/ipxe/".alias = "/etc/pxe/ipxe/";
  };

  # Provide a tiny, non-destructive iPXE script (HTTP-served)
  environment.etc."pxe/ipxe/test.ipxe".text = ''
    #!ipxe
    dhcp
    echo iPXE OK: MAC $''${net0/mac} IP $''${net0/ip}
    sleep 2
    echo Booting local disk in 3s... (Ctrl-B for iPXE shell)
    sleep 3
    sanboot --no-describe --drive 0x80 || exit
  '';

  # --- DNSMASQ: proxyDHCP + TFTP + iPXE chainloading ---
  services.dnsmasq = {
    enable = true;

    # If you want to bind to a specific NIC later, uncomment the next line:
    # interfaces = [ "ens18" ];

    settings = {
      # TFTP service for first-stage loaders
      enable-tftp = true;
      tftp-root = tftpRoot;

      # SAFEST default: proxyDHCP (do not hand out addresses)
      # Replace 10.0.0.0 with your LAN's network if different.
      "dhcp-range" = "10.0.0.0,proxy";

      # Tag clients by architecture and by whether they're already running iPXE
      "dhcp-match" = [
        "set:ipxe,175"                         # iPXE sets option 175
        "set:efi64,option:client-arch,7"       # x86_64 UEFI
        "set:bios,option:client-arch,0"        # legacy BIOS
      ];

      # iPXE clients get the HTTP script; non‑iPXE clients get an iPXE binary
      "dhcp-boot" = [
        "tag:ipxe,http://pxe.local/ipxe/test.ipxe"
        "tag:efi64,ipxe.efi"
        "tag:bios,undionly.kpxe"
      ];

      # Optional cosmetic prompt in some PXE BIOSes
      "pxe-prompt" = "\"Network boot (press F8 for menu)\", 5";
    };
  };

  # Open the right ports
  networking.firewall.allowedTCPPorts = [ 80 ];
  # 67 (DHCP), 4011 (proxyDHCP), 69 (TFTP)
  networking.firewall.allowedUDPPorts = [ 67 69 4011 ];

  # One-shot helper to fetch iPXE binaries into /srv/tftp (easy first pass)
  systemd.services."pxe-fetch-ipxe" = {
    description = "Fetch iPXE chainloaders into TFTP root";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      install -d -m0755 ${tftpRoot}
      cd ${tftpRoot}
      if [ ! -s undionly.kpxe ]; then
        ${pkgs.curl}/bin/curl -fsSLo undionly.kpxe https://boot.ipxe.org/undionly.kpxe
      fi
      if [ ! -s ipxe.efi ]; then
        ${pkgs.curl}/bin/curl -fsSLo ipxe.efi https://boot.ipxe.org/ipxe.efi
      fi
    '';
  };
}
