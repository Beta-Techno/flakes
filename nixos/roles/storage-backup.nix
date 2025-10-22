{ config, pkgs, lib, ... }:

let
  storageDashboard = pkgs.writeTextDir "index.html" ''
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <title>Storage Backup</title>
    <style>body{font-family:system-ui;margin:40px;max-width:800px}
    .box{border:1px solid #ddd;border-radius:6px;padding:16px;margin:16px 0}</style>
    </head><body>
    <h1>Backup Server</h1>
    <div class="box"><h2>Paths</h2>
      <ul>
        <li>/var/storage/backups/{netbox,pxe,infrastructure}</li>
        <li>/var/storage/vm-snapshots/{daily,weekly,monthly}</li>
        <li>/var/storage/archives/{logs,configs}</li>
      </ul>
    </div>
    <div class="box"><h2>Incoming</h2>
      <pre>ssh backup@storage-backup-01
rsync -az --mkpath src/ backup@storage-backup-01:/var/storage/backups/&lt;app&gt;/&lt;host&gt;/&lt;ts&gt;/</pre>
    </div>
    </body></html>
  '';
in
{
  imports = [
    ../profiles/base.nix
    ../profiles/nginx.nix
    ../profiles/sops.nix
    ../profiles/nvim-tiny-plugins.nix
    ../profiles/observability/client.nix
  ];

  system.stateVersion = "24.11";

  # Dedicated backup user
  users.groups.backup = { };
  users.users.backup = {
    isNormalUser = true;
    createHome = true;
    home = "/home/backup";
    group = "backup";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = lib.mkForce [ ]; # managed by SOPS template
  };

  # Minimal, locked-down SSH for backup pushes
  services.openssh.extraConfig = ''
    Match User backup
      PasswordAuthentication no
      PubkeyAuthentication yes
      X11Forwarding no
      AllowAgentForwarding no
      AllowTcpForwarding no
      PermitTunnel no
  '';

  # Authorize NetBox public key via SOPS
  sops.templates."authorized_keys.backup" = {
    content = config.sops.placeholder."netbox-backup-public-key";
    owner = "backup"; group = "backup"; mode = "0600";
    path = "/home/backup/.ssh/authorized_keys";
  };

  # Directory layout for backups
  systemd.tmpfiles.rules = [
    "d /var/storage/backups 0755 backup backup -"
    "d /var/storage/backups/netbox 0755 backup backup -"
    "d /var/storage/backups/pxe 0755 backup backup -"
    "d /var/storage/backups/infrastructure 0755 backup backup -"
    "d /var/storage/vm-snapshots 0755 backup backup -"
    "d /var/storage/vm-snapshots/daily 0755 backup backup -"
    "d /var/storage/vm-snapshots/weekly 0755 backup backup -"
    "d /var/storage/vm-snapshots/monthly 0755 backup backup -"
    "d /var/storage/archives 0755 backup backup -"
    "d /var/storage/archives/logs 0755 backup backup -"
    "d /var/storage/archives/configs 0755 backup backup -"
    "d /home/backup/.ssh 0700 backup backup -"
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Tiny static page (nice for smoke tests)
  services.nginx.virtualHosts."storage.local" = {
    default = true;
    root = storageDashboard;
    locations."/" = { tryFiles = "$uri $uri/ /index.html"; };
  };

  environment.systemPackages = with pkgs; [ rsync restic zstd jq ];
}
