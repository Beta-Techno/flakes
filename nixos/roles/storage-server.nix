# Storage server role - centralized backup and storage
{ config, pkgs, lib, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/nginx.nix
  ];

  system.stateVersion = "24.11";

  # Enable SMB/CIFS for network shares
  services.samba = {
    enable = true;
    openFirewall = true;
    shares = {
      # Application backups
      netbox-backups = {
        path = "/var/storage/backups/netbox";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "backup";
      };
      pxe-backups = {
        path = "/var/storage/backups/pxe";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "backup";
      };
      
      # VM snapshots
      vm-snapshots = {
        path = "/var/storage/vm-snapshots";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "backup";
      };
      
      # Long-term storage
      archives = {
        path = "/var/storage/archives";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "backup";
      };
    };
  };

  # Create storage directories and web dashboard
  systemd.tmpfiles.rules = [
    # Application backups
    "d /var/storage/backups/netbox 0755 backup backup -"
    "d /var/storage/backups/pxe 0755 backup backup -"
    "d /var/storage/backups/infrastructure 0755 backup backup -"
    
    # VM snapshots
    "d /var/storage/vm-snapshots 0755 backup backup -"
    "d /var/storage/vm-snapshots/daily 0755 backup backup -"
    "d /var/storage/vm-snapshots/weekly 0755 backup backup -"
    "d /var/storage/vm-snapshots/monthly 0755 backup backup -"
    
    # Long-term storage
    "d /var/storage/archives 0755 backup backup -"
    "d /var/storage/archives/logs 0755 backup backup -"
    "d /var/storage/archives/configs 0755 backup backup -"
    
    # Web dashboard
    "d /var/www/storage-dashboard 0755 nginx nginx -"
  ];

  # Create backup user
  users.users.backup = {
    isNormalUser = true;
    extraGroups = [ "wheel" "backup" ];
    shell = pkgs.bash;
    # Set password manually: sudo passwd backup
  };

  # Backup management tools
  environment.systemPackages = with pkgs; [
    # Backup tools
    rsync
    rclone
    restic
    duplicity
    
    # VM management
    qemu
    libvirt
    
    # Monitoring
    htop
    iotop
    ncdu
    smartmontools
    
    # Network tools
    nmap
    tcpdump
    
    # Database tools (for testing restores)
    postgresql_15
    pgcli
  ];

  # Firewall rules
  networking.firewall.allowedTCPPorts = [
    22   # SSH
    80   # HTTP
    443  # HTTPS
    445  # SMB
    139  # NetBIOS
  ];

  # Web interface for storage management
  services.nginx.virtualHosts."storage.local" = {
    root = "/var/www/storage-dashboard";
    locations."/" = {
      tryFiles = "$uri $uri/ /index.html";
    };
  };

  # Create a simple storage dashboard (directory created above in tmpfiles.rules)

  # Simple storage dashboard HTML
  environment.etc."storage-dashboard/index.html".text = ''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Storage Server Dashboard</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 800px; margin: 0 auto; }
            .section { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
            .status { color: green; font-weight: bold; }
            pre { background: #f5f5f5; padding: 10px; border-radius: 3px; overflow-x: auto; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Storage Server Dashboard</h1>
            
            <div class="section">
                <h2>Storage Status</h2>
                <p class="status">✓ Storage server is running</p>
                <p>Available shares:</p>
                <ul>
                    <li><strong>netbox-backups</strong> - Netbox database and media backups</li>
                    <li><strong>pxe-backups</strong> - PXE server configurations</li>
                    <li><strong>vm-snapshots</strong> - Proxmox VM snapshots</li>
                    <li><strong>archives</strong> - Long-term storage</li>
                </ul>
            </div>
            
            <div class="section">
                <h2>Quick Commands</h2>
                <p>Connect to storage shares:</p>
                <pre># From Linux/Mac
smbclient //storage.local/netbox-backups -U backup

# From Windows
\\storage.local\netbox-backups</pre>
            </div>
            
            <div class="section">
                <h2>Backup Status</h2>
                <p>Check backup directories:</p>
                <pre>ls -la /var/storage/backups/</pre>
            </div>
        </div>
    </body>
    </html>
  '';
}
