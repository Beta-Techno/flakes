# Ingress-01 Deployment Guide

This guide covers deploying the ingress-01 VM, which serves as the single front door for all HTTP(S) traffic to Beta Technology infrastructure.

## Architecture Overview

```
Internet → Cloudflare Edge → Cloudflare Tunnel → ingress-01 (nginx + cloudflared)
                                                     ↓
                                    ┌────────────────┼────────────────┐
                                    ↓                ↓                ↓
                              NixOS Services    K8s Services    Observability
                              (netbox, pxe)    (*.k8s.*)       (grafana, prom)
```

**Key Design Decisions:**
- **Single ingress VM**: One canonical front door simplifies routing and debugging
- **Nginx for NixOS services**: Static routes for infrastructure (netbox, observability, media)
- **Traefik for K8s**: Dynamic routes for application workloads (*.k8s.betatechnology.org)
- **Cloudflared colocated**: Tunnel daemon runs on ingress-01 (no separate tunnel VM)
- **Zero public ports**: Cloudflare Tunnel is outbound-only; no ports 80/443 exposed to internet

## Prerequisites

### 1. Cloudflare Tunnel Setup

Before deploying ingress-01, create the Cloudflare Tunnel in Zero Trust dashboard:

1. **Login to Cloudflare Zero Trust**: https://one.dash.cloudflare.com/
2. **Navigate to Networks → Tunnels**
3. **Create a new tunnel**:
   - Name: `beta-ingress`
   - Connector type: `Cloudflared`
4. **Download the credentials JSON**:
   - Save as `beta-ingress-credentials.json`
   - This file contains the tunnel ID and authentication token

### 2. Add Tunnel Credentials to SOPS

The credentials JSON must be encrypted with SOPS and added to `secrets/prod.yaml`:

```bash
# Navigate to flakes directory
cd /Users/nbend/dev/infrastructure/flakes

# Edit the encrypted secrets file
sops secrets/prod.yaml
```

Add the following entry to the YAML file:

```yaml
cloudflared-beta-creds: |
  {
    "AccountTag": "your-account-tag",
    "TunnelID": "your-tunnel-id",
    "TunnelSecret": "your-tunnel-secret"
  }
```

**Important**: Paste the entire contents of `beta-ingress-credentials.json` as a multi-line string.

Save and exit. SOPS will automatically re-encrypt the file with the configured age keys.

### 3. Configure Cloudflare DNS

Create CNAME records pointing to the tunnel:

| Hostname | Type | Target |
|----------|------|--------|
| netbox.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |
| obs.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |
| media.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |
| stream.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |
| pxe.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |
| *.k8s.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |

**Note**: The tunnel ID is visible in the Cloudflare dashboard after creating the tunnel.

### 4. Provision VM in Proxmox

Create a new VM with the following specs:

- **Name**: ingress-01
- **OS**: NixOS (minimal ISO)
- **CPU**: 2 vCPU
- **Memory**: 2GB RAM
- **Disk**: 20GB
- **Network**: vmbr0 (LAN bridge)
- **IP**: 10.0.0.11 (static or DHCP reservation)

Install NixOS with a basic configuration:

```bash
# On the VM console
# 1. Partition disk
# 2. Install NixOS minimal config
# 3. Enable SSH and allow root login temporarily
```

## Deployment Steps

### Step 1: Verify Configuration Builds

Before deploying, verify the configuration compiles:

```bash
# From your laptop/workstation
cd /Users/nbend/dev/infrastructure/flakes

# Build ingress-01 configuration
nix build .#nixosConfigurations.ingress-01.config.system.build.toplevel

# Check for errors
echo $?  # Should output 0 if successful
```

### Step 2: Deploy to VM

Deploy the configuration to ingress-01:

```bash
# Using nixos-deploy wrapper
nix run .#nixos-deploy -- ingress-01 -H root@10.0.0.11

# Or using nixos-rebuild directly
nixos-rebuild switch --flake .#ingress-01 \
  --target-host root@10.0.0.11 \
  --build-host localhost
```

**First deployment notes:**
- You may be prompted for root password (temporary initial password)
- SSH host key will be added to known_hosts
- Deployment takes 5-10 minutes on first run (building packages)

### Step 3: Verify Deployment

After deployment completes, verify services are running:

```bash
# SSH into ingress-01
ssh nbg@10.0.0.11

# Check nginx status
sudo systemctl status nginx

# Check cloudflared tunnel status
sudo systemctl status cloudflared

# Check firewall status
sudo nftables list ruleset | grep -A5 "chain input"

# Verify ports are open
sudo ss -tulnp | grep -E ':(80|443) '
```

### Step 4: Test Routing

#### Test LAN Access (Internal)

From a machine on the LAN (10.0.0.0/24):

```bash
# Test Netbox routing
curl -v -H "Host: netbox.local" http://10.0.0.11/api/status/

# Test Observability routing
curl -v -H "Host: observability.local" http://10.0.0.11/

# Test Jellyfin routing
curl -v -H "Host: media.local" http://10.0.0.11/
```

Expected: HTTP 200 responses from backend services.

#### Test Public Access (via Cloudflare Tunnel)

From any machine with internet access:

```bash
# Test Netbox via tunnel
curl -v https://netbox.betatechnology.org/api/status/

# Test Observability via tunnel
curl -v https://obs.betatechnology.org/

# Test Jellyfin via tunnel
curl -v https://media.betatechnology.org/
```

Expected: HTTPS 200 responses, TLS terminated by Cloudflare.

#### Test K8s Wildcard (After k3s deployment)

```bash
# Test K8s ingress routing
curl -v https://demo.k8s.betatechnology.org/
```

Expected: Proxied to k3s-01:80 (Traefik ingress controller).

### Step 5: Verify Monitoring

Check that observability-01 is scraping metrics from ingress-01:

```bash
# On observability-01 or via Grafana
curl http://observability-01:9090/api/v1/query?query=up{job="node-exporter",instance="ingress-01:9100"}
```

Expected: `"value": [timestamp, "1"]` (instance is up).

## Troubleshooting

### Cloudflare Tunnel Not Connecting

```bash
# Check cloudflared logs
sudo journalctl -u cloudflared -f

# Common issues:
# - Invalid credentials: Check secrets/prod.yaml has correct JSON
# - Tunnel not active in Cloudflare dashboard: Activate tunnel
# - Network firewall blocking outbound: Ensure port 443 outbound allowed
```

### Nginx 502 Bad Gateway

```bash
# Check nginx logs
sudo journalctl -u nginx -f

# Common issues:
# - Backend service down: Check netbox-01, observability-01, etc. are running
# - Incorrect backend hostname: Verify /etc/hosts or DNS resolution
# - Backend firewall: Ensure backend allows traffic from ingress-01
```

### Backend Services Not Resolving

```bash
# Check DNS resolution
dig netbox-01
dig observability-01

# If using /etc/hosts, verify entries:
cat /etc/hosts | grep -E '(netbox|observability|k3s)'

# If using Tailscale MagicDNS:
tailscale status | grep -E '(netbox|observability|k3s)'
```

### Firewall Blocking Traffic

```bash
# Check if ports 80/443 are open
sudo nft list table inet filter | grep -A20 "chain input"

# Manually allow ports (temporary, for debugging)
sudo nft add rule inet filter input tcp dport {80, 443} accept

# Rebuild configuration to fix permanently
nixos-rebuild switch --flake .#ingress-01
```

## Post-Deployment Tasks

### 1. Disable Ubuntu Ingress VM

Once ingress-01 is verified working:

1. **Update Cloudflare DNS**: Point all records to new tunnel
2. **Monitor traffic**: Ensure no requests to old Ubuntu VM
3. **Shutdown Ubuntu VM**: `sudo shutdown -h now`
4. **Remove from inventory**: Update documentation

### 2. Enable Cloudflare Access (Optional)

For admin paths (Grafana admin, Netbox admin):

1. **Navigate to Cloudflare Zero Trust → Access**
2. **Create application**:
   - Name: "Grafana Admin"
   - Domain: `obs.betatechnology.org`
   - Path: `/admin/*`
3. **Add policy**:
   - Name: "Admin Only"
   - Action: Allow
   - Include: Email = `admin@betatechnology.org`

### 3. Set Up Alerting

Create Prometheus alerts for ingress-01:

```yaml
# In observability/alerts/ingress.yml
groups:
  - name: ingress
    rules:
      - alert: IngressDown
        expr: up{job="node-exporter",instance="ingress-01:9100"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Ingress-01 is down"

      - alert: NginxDown
        expr: nginx_up{instance="ingress-01"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Nginx on ingress-01 is down"

      - alert: CloudflaredDown
        expr: absent(cloudflared_tunnel_up{instance="ingress-01"})
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Cloudflare tunnel disconnected"
```

## Maintenance

### Updating Nginx Configuration

To add a new service route:

1. **Edit `nixos/roles/ingress.nix`**:
   ```nix
   "newservice.betatechnology.org" = {
     locations."/" = {
       proxyPass = "http://newservice-01:8080";
       proxyWebsockets = true;
     };
   };
   ```

2. **Add to Cloudflare tunnel ingress rules**:
   ```nix
   {
     hostname = "newservice.betatechnology.org";
     service = "http://localhost";
   }
   ```

3. **Rebuild and deploy**:
   ```bash
   nixos-rebuild switch --flake .#ingress-01 --target-host root@10.0.0.11
   ```

4. **Add DNS CNAME** in Cloudflare dashboard

### Rotating Cloudflare Tunnel Credentials

If credentials are compromised:

1. **Delete old tunnel** in Cloudflare Zero Trust
2. **Create new tunnel** with new name
3. **Download new credentials JSON**
4. **Update `secrets/prod.yaml`**:
   ```bash
   sops secrets/prod.yaml
   # Replace cloudflared-beta-creds with new JSON
   ```
5. **Redeploy ingress-01**:
   ```bash
   nixos-rebuild switch --flake .#ingress-01
   ```

## Architecture Decisions Reference

### Why Not Traefik for Infrastructure Services?

- **Nix-native**: nginx config is declarative Nix (`services.nginx.virtualHosts`)
- **Static routes**: Infrastructure services don't change often; auto-discovery overkill
- **Simplicity**: One file to understand all routing (`nixos/roles/ingress.nix`)
- **Agent-friendly**: AI can easily parse and modify Nix config

### Why Colocate Tunnel on Ingress VM?

- **Single edge host**: Clear mental model ("ingress-01 is the front door")
- **Lightweight daemon**: cloudflared is tiny, no need for separate VM
- **Simpler routing**: Tunnel → localhost → nginx (all in one place)
- **Easier debugging**: Logs and configs in one location

### Why Not Open Ports 80/443 to Internet?

- **Zero trust**: Cloudflare Tunnel is outbound-only (no listening ports)
- **DDoS protection**: Cloudflare handles all attacks
- **Free TLS**: Cloudflare provides certificates
- **Access policies**: Can add SSO via Cloudflare Access

## Next Steps

After ingress-01 is deployed:

1. **Phase 2**: Add Alertmanager and expand monitoring
2. **Phase 3**: Expand K8s cluster (k3s-02, k3s-03)
3. **Phase 4**: Security hardening (firewall, Cloudflare Access, auditd)
4. **Phase 5**: Backup automation and DR testing

---

**Created**: 2025-01-06
**Author**: Claude Code
**Status**: Ready for production deployment
