# Phase 1: Edge & Ingress - COMPLETE ✅

**Status**: Ready for deployment
**Date**: 2025-01-06
**Architect**: Claude Code

---

## What Was Built

### 1. Ingress Role (`nixos/roles/ingress.nix`)

A complete NixOS role that provides:

**Nginx Reverse Proxy Configuration:**
- Infrastructure services (Netbox, Observability, PXE)
- Media services (Jellyfin, MediaMTX)
- K8s wildcard routing (`*.k8s.betatechnology.org` → Traefik on k3s-01)
- Security: Default deny (catch-all returns 444 for unknown hosts)
- Both public (`.betatechnology.org`) and LAN (`.local`) hostname support

**Cloudflare Tunnel Integration:**
- Tunnel configuration for `beta-ingress`
- Ingress rules mapping public hostnames to localhost
- Credentials loaded from SOPS secrets
- Automatic restart on failure

**Key Features:**
- Proper proxy headers for all services (Host, X-Real-IP, X-Forwarded-For, X-Forwarded-Proto)
- WebSocket support for all routes
- Buffering disabled for media streams (Jellyfin, MediaMTX)
- Nginx status endpoint for Prometheus monitoring

### 2. Host Configuration (`nixos/hosts/servers/ingress-01.nix`)

Complete host-specific configuration:
- UEFI boot with systemd-boot
- VM-optimized (virtio modules)
- Filesystem mounts by label (flexible for different disk layouts)
- Static IP: 10.0.0.11 (DHCP with reservation recommended)
- DNS resolution for backend services
- User configuration (nbg admin user)
- Comprehensive inline documentation

### 3. Inventory Entry (`inventories/prod.nix`)

Added ingress-01 to production inventory:
- Role: `ingress`
- IP: `10.0.0.11`
- Organized under "EDGE & INGRESS" section
- Clean separation from infrastructure services

### 4. Deployment Documentation (`docs/ingress-01-deployment.md`)

Complete deployment guide covering:
- Architecture overview and design decisions
- Cloudflare Tunnel setup (step-by-step)
- SOPS secrets configuration
- DNS configuration
- VM provisioning specs
- Deployment procedures
- Testing and verification steps
- Troubleshooting common issues
- Maintenance procedures

---

## Files Created

```
nixos/roles/ingress.nix                  # 300+ lines of nginx + cloudflared config
nixos/hosts/servers/ingress-01.nix       # Host-specific configuration
inventories/prod.nix                     # Updated with ingress-01 entry
docs/ingress-01-deployment.md            # Complete deployment guide
docs/PHASE-1-COMPLETE.md                 # This summary
```

---

## What You Need to Do Before Deployment

### Step 1: Create Cloudflare Tunnel

1. Login to **Cloudflare Zero Trust**: https://one.dash.cloudflare.com/
2. Navigate to **Networks → Tunnels**
3. Click **Create a tunnel**
4. Name: `beta-ingress`
5. Connector type: `Cloudflared`
6. Download the **credentials JSON** file

### Step 2: Add Credentials to SOPS

```bash
cd /Users/nbend/dev/infrastructure/flakes

# Edit encrypted secrets
sops secrets/prod.yaml
```

Add this entry (paste your actual credentials):

```yaml
cloudflared-beta-creds: |
  {
    "AccountTag": "your-account-tag-here",
    "TunnelID": "your-tunnel-id-here",
    "TunnelSecret": "your-secret-here"
  }
```

Save and exit. SOPS will re-encrypt automatically.

### Step 3: Configure Cloudflare DNS

Create CNAME records (all pointing to `<tunnel-id>.cfargotunnel.com`):

- `netbox.betatechnology.org`
- `obs.betatechnology.org`
- `media.betatechnology.org`
- `stream.betatechnology.org`
- `pxe.betatechnology.org`
- `*.k8s.betatechnology.org` (wildcard)

### Step 4: Provision VM in Proxmox

- **Name**: ingress-01
- **CPU**: 2 vCPU
- **RAM**: 2GB
- **Disk**: 20GB
- **Network**: vmbr0 (LAN bridge)
- **IP**: 10.0.0.11 (static or DHCP reservation)

Install NixOS minimal, enable SSH temporarily.

### Step 5: Deploy

```bash
# From a Linux machine or use remote builders
nix build .#nixosConfigurations.ingress-01.config.system.build.toplevel

# Deploy to VM
nix run .#nixos-deploy -- ingress-01 -H root@10.0.0.11

# Or using nixos-rebuild
nixos-rebuild switch --flake .#ingress-01 \
  --target-host root@10.0.0.11 \
  --build-host localhost
```

### Step 6: Verify

```bash
# Test LAN access
curl -H "Host: netbox.local" http://10.0.0.11/api/status/

# Test public access
curl https://netbox.betatechnology.org/api/status/

# Check services
ssh nbg@10.0.0.11
sudo systemctl status nginx
sudo systemctl status cloudflared
```

---

## Architecture Highlights

### Design Principle: Single Front Door

```
Internet
   ↓
Cloudflare Edge (DDoS, TLS, WAF)
   ↓
Cloudflare Tunnel (encrypted, outbound-only)
   ↓
ingress-01 (10.0.0.11)
   ├─ nginx (reverse proxy)
   └─ cloudflared (tunnel client)
       ↓
   ┌───┴───┬───────────┬─────────────┐
   ↓       ↓           ↓             ↓
NixOS   Media      K8s         Observability
Services Services  (Traefik)   (Grafana)
```

### Why This Design?

**1. Single Logical Ingress**
- One VM to understand, monitor, debug
- One place to add new routes (nixos/roles/ingress.nix)
- Clear mental model: "ingress-01 is the edge"

**2. Two Routing Tiers**
- **Tier 1**: Nginx for NixOS services (static, infrastructure)
- **Tier 2**: Traefik for K8s workloads (dynamic, applications)

**3. Nginx vs Traefik for Infrastructure**
- Nix-native configuration (`services.nginx.virtualHosts`)
- Declarative, type-safe, Git-versioned
- AI/agent can easily read and modify
- Perfect for static routes that rarely change

**4. Cloudflare Tunnel Benefits**
- Zero open ports to internet (outbound-only connection)
- Free DDoS protection and TLS
- Can add SSO via Cloudflare Access
- No need for port forwarding or public IPs

**5. Security by Default**
- Unknown hosts return 444 (close connection)
- SSH only on Tailscale
- Prometheus metrics only on Tailscale
- Firewall allows only 80/443 on LAN interface

---

## What's Next: Phase 2

After ingress-01 is deployed and verified:

### Phase 2: Observability Enhancement (1 week)

**Goals:**
- Add Alertmanager for alert routing
- Expand Grafana dashboards (ingress-overview, alerts-overview, media-pipeline)
- Deploy kube-prometheus-stack for K8s monitoring
- Set up Prometheus federation (K8s → Central)

**Deliverables:**
- Email/Slack alerts for critical issues
- Comprehensive dashboards for all services
- K8s cluster metrics in central Grafana

### Phase 3: K8s Cluster Expansion (2 weeks)

**Goals:**
- Deploy k3s-02 and k3s-03 worker nodes
- Install NFS CSI Driver, ArgoCD, Velero
- Deploy first GitOps-managed application

**Deliverables:**
- 3-node HA Kubernetes cluster
- GitOps workflow via ArgoCD
- Automated K8s backups via Velero

---

## Testing Checklist

Before considering Phase 1 complete, verify:

- [ ] ingress-01 VM deployed and accessible
- [ ] Nginx serving traffic on ports 80/443
- [ ] Cloudflared tunnel connected and healthy
- [ ] Netbox accessible via `netbox.betatechnology.org`
- [ ] Observability accessible via `obs.betatechnology.org`
- [ ] Jellyfin accessible via `media.betatechnology.org`
- [ ] MediaMTX accessible via `stream.betatechnology.org`
- [ ] All services accessible via `.local` hostnames on LAN
- [ ] Prometheus scraping ingress-01 metrics
- [ ] Nginx logs visible in Loki
- [ ] Ubuntu ingress VM decommissioned (if applicable)

---

## Key Files Reference

**Configuration:**
- `nixos/roles/ingress.nix` - Nginx + Cloudflared config
- `nixos/hosts/servers/ingress-01.nix` - Host config
- `inventories/prod.nix` - Production inventory
- `secrets/prod.yaml` - SOPS-encrypted secrets (add cloudflared-beta-creds)

**Documentation:**
- `docs/ingress-01-deployment.md` - Deployment guide
- `docs/PHASE-1-COMPLETE.md` - This file

**Monitoring:**
- Prometheus: `http://observability-01:9090/targets` (check ingress-01 target)
- Grafana: `http://observability-01:3000/dashboards` (view host-overview)
- Loki: Check nginx logs with LogQL

---

## Support & Troubleshooting

### Common Issues

**Cloudflare tunnel won't connect:**
```bash
sudo journalctl -u cloudflared -f
# Check credentials JSON is valid
# Verify tunnel is active in Cloudflare dashboard
```

**Nginx 502 Bad Gateway:**
```bash
sudo journalctl -u nginx -f
# Check backend service is running
# Verify DNS/hostname resolution
# Test direct connection: curl http://netbox-01:80
```

**Backend not resolving:**
```bash
dig netbox-01
cat /etc/hosts | grep netbox
tailscale status | grep netbox
```

### Getting Help

- Check deployment guide: `docs/ingress-01-deployment.md`
- Review architecture doc (this file)
- Check Nginx config: `cat /etc/nginx/nginx.conf`
- Check Cloudflared config: `systemctl cat cloudflared`

---

## Acknowledgments

This architecture implements the "dream system" design from the comprehensive planning session:

- **Nix is the control plane**: All configuration declarative, Git-versioned
- **Single source of truth**: `inventories/prod.nix` defines reality
- **Explicit over implicit**: Routing is transparent, no magic auto-discovery
- **Secure by default**: Tailscale for mgmt, Cloudflare for public, firewall locked down
- **Observable from day one**: Every host monitored, logged, alerted

---

**Phase 1 Status: ✅ READY FOR DEPLOYMENT**

The foundation is built. Deploy when ready. The dream system is taking shape. 🚀
