# NixOS Infrastructure

This directory contains NixOS configurations for production servers and workstations.

## Directory Structure

```
nixos/
├── profiles/           # Reusable system configurations
│   ├── base.nix       # Basic system setup (SSH, users, firewall)
│   ├── docker-daemon.nix  # Docker daemon and container management
│   ├── nginx.nix      # Web server configuration
│   ├── cloudflared-system.nix  # Cloudflare tunnel system service
│   └── postgres.nix   # PostgreSQL database configuration
├── roles/             # Bundles of profiles for specific purposes
│   ├── server.nix     # General server role (base + docker + nginx + cloudflared)
│   ├── workstation.nix  # Development workstation role (base + docker + GUI)
│   └── db-server.nix  # Database server role (server + postgres)
└── hosts/             # Concrete machine configurations
    ├── servers/       # Production server hosts
    │   ├── web-01.nix # Web server with nginx and cloudflared
    │   └── db-01.nix  # Database server with PostgreSQL
    └── workstations/  # Development workstation hosts
        └── nick-laptop.nix  # Personal laptop with Home-Manager embedded
```

## Usage

### Deploy to a Server

```bash
# Deploy to web-01 server
nixos-rebuild switch --flake .#web-01

# Deploy to database server
nixos-rebuild switch --flake .#db-01
```

### Deploy to a Workstation

```bash
# Deploy to personal laptop
nixos-rebuild switch --flake .#nick-laptop
```

### Build Configuration

```bash
# Build configuration without applying
nixos-rebuild build --flake .#web-01

# Build and test configuration
nixos-rebuild test --flake .#web-01
```

## Profiles

### Base Profile (`profiles/base.nix`)
- Nix flakes support
- SSH server configuration
- Basic system packages
- User management
- Firewall configuration

### Docker Daemon Profile (`profiles/docker-daemon.nix`)
- Docker daemon setup
- OCI container management
- User group configuration
- Docker registry settings

### Nginx Profile (`profiles/nginx.nix`)
- Web server configuration
- SSL/TLS with Let's Encrypt
- Security headers
- Rate limiting

### Cloudflare Tunnel Profile (`profiles/cloudflared-system.nix`)
- System-level tunnel service
- Ingress rule configuration
- Automatic restart

### PostgreSQL Profile (`profiles/postgres.nix`)
- Database server setup
- User and database creation
- Performance tuning
- SSL configuration

## Roles

### Server Role (`roles/server.nix`)
Bundles: base + docker-daemon + nginx + cloudflared-system
- Production server configuration
- Monitoring and logging
- Automatic updates
- Backup configuration

### Workstation Role (`roles/workstation.nix`)
Bundles: base + docker-daemon
- GUI desktop environment
- Development tools
- Media support
- Hardware configuration

### Database Server Role (`roles/db-server.nix`)
Bundles: server + postgres
- Database-optimized configuration
- Performance tuning
- Backup and monitoring
- Replication support

## Hosts

### Web Server (`hosts/servers/web-01.nix`)
- Nginx virtual hosts for API and web app
- Cloudflare tunnel configuration
- Web development tools

### Database Server (`hosts/servers/db-01.nix`)
- PostgreSQL with multiple databases
- Backup configuration
- Database monitoring
- Performance optimization

### Development Laptop (`hosts/workstations/nick-laptop.nix`)
- Embedded Home-Manager configuration
- GUI desktop environment
- Development tools
- Hardware-specific settings

## Integration with Home-Manager

Workstation hosts embed Home-Manager configurations to reuse your existing:
- Editor configurations (VSCode, LazyVim, Doom Emacs)
- Terminal configurations (Alacritty, tmux)
- GUI configurations (themes, fonts)
- Tool configurations (Docker client, Kubernetes tools)

This provides a seamless experience between Ubuntu/macOS development and NixOS workstations.

## Adding New Hosts

1. **Create a new host file** in `hosts/servers/` or `hosts/workstations/`
2. **Import appropriate role** (server, workstation, db-server)
3. **Add host-specific configuration**
4. **Add to flake.nix** in `nixosConfigurations`
5. **Deploy** with `nixos-rebuild switch --flake .#hostname`

## Security Notes

- SSH keys need to be added to the base profile
- Cloudflare tunnel credentials need to be placed in `/etc/cloudflared/`
- Database passwords should be managed with secrets management
- Firewall rules are configured per profile

