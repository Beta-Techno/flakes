# Rebuild Infrastructure From Zero

**Purpose**: Complete teardown and rebuild of all NixOS infrastructure
**Status**: Planning Document
**Risk Level**: High (full production rebuild)
**Estimated Time**: 2-3 days for complete rebuild

---

## Why This Is Actually Smart

Starting from zero gives you:

✅ **Clean foundation** - No legacy cruft or half-configured systems
✅ **Correct deployment order** - Dependencies handled properly
✅ **Tested configurations** - Every host config proven to work
✅ **Documented process** - Runbook for future disaster recovery
✅ **Fresh secrets** - New age keys, rotated credentials
✅ **Monitoring from day one** - Observability deployed first

**The key**: Deploy in dependency order, test each layer before proceeding.

---

## Phase 0: Pre-Cleanup Preparation

### Step 0.1: Backup Critical Data

**Before deleting anything**, backup:

1. **Netbox database** (if you have production data):
   ```bash
   # From current netbox host
   docker exec netbox-postgres pg_dump -U netbox > netbox-backup-$(date +%Y%m%d).sql
   scp netbox-backup-*.sql laptop:~/backups/
   ```

2. **Media files** (if any irreplaceable content):
   ```bash
   # From storage-media host
   rsync -avz /srv/media/ laptop:~/backups/media/
   ```

3. **Git repo secrets/config** (already backed up in git, but verify):
   ```bash
   git push  # Ensure latest changes pushed
   git log --oneline -5  # Verify commits
   ```

4. **SSH keys** (if any host-specific keys you want to preserve):
   ```bash
   # From each host if needed
   scp root@HOST:/root/.ssh/id_* laptop:~/backups/ssh/
   ```

### Step 0.2: Document Current State

Capture what exists now (for reference):

```bash
# Run dump-info.sh to snapshot current config
./dump-info.sh > ~/backups/infrastructure-snapshot-$(date +%Y%m%d).txt

# List all VMs in Proxmox
# (from Proxmox host or via web UI)
qm list

# Document IP allocations
cat /etc/hosts  # or wherever you track IPs
```

### Step 0.3: Prepare Clean Flake Repo

Clean up the repo for fresh start:

```bash
cd /Users/nbend/dev/infrastructure/flakes

# Create a clean branch
git checkout -b rebuild-from-zero

# Clean up .sops.yaml - remove ALL old host keys
# Keep only your admin keys for now
```

**Edit `.sops.yaml`** to only include admin keys:

```yaml
creation_rules:
  - path_regex: ^secrets/prod\.ya?ml$
    age: >-
      age1ycfwrad25wrjguqx4um7mck9s0xxc90dd4uytcz68wz2kcf3n4gqjejqhz,
      age1fzfm3rtt7pz53c95dvcup3fwh6gfdmupjgvt6wlsxg333fhzt3vshq6l5f
```

(Keep only known admin keys, remove all host keys)

```bash
# Rekey secrets with only admin keys
sops updatekeys secrets/prod.yaml

# Commit clean state
git add .sops.yaml secrets/prod.yaml
git commit -m "Clean up age keys for rebuild"
```

---

## Phase 1: Teardown

### Step 1.1: Stop All Services Gracefully

**From each VM** (if you want clean shutdown):

```bash
# For VMs with important services
systemctl stop nginx
systemctl stop docker
systemctl stop postgresql
# etc.
```

Or just shut down VMs from Proxmox (faster):

```bash
# From Proxmox host
qm stop <VMID>
```

### Step 1.2: Delete VMs in Proxmox

**From Proxmox web UI** or CLI:

```bash
# List VMs
qm list

# Delete each VM (this removes disk too)
qm destroy <VMID>

# Or delete all NixOS VMs at once (BE CAREFUL!)
# Verify IDs first!
for vmid in 100 101 102 103; do
  qm destroy $vmid
done
```

### Step 1.3: Clean Up Storage (Optional)

If you have dedicated storage for VMs:

```bash
# From Proxmox host
# List storage
pvesm status

# Remove old VM disks if needed
# (Usually qm destroy handles this)
```

---

## Phase 2: Deployment Order (Critical!)

**Deploy in this exact order** - respects dependencies:

```
1. observability-01      (monitoring first - see everything else boot)
2. storage-backup-01     (backup target - isolated, no dependencies)
3. storage-media-01      (NFS/SMB - media services need this)
4. ingress-01            (front door - before services that need public access)
5. netbox-01             (IPAM - useful for tracking remaining deployments)
6. pxe-01                (network boot - optional, low priority)
7. jellyfin-01           (media server - depends on storage-media)
8. mediamtx-01           (streaming - depends on storage-media)
9. k3s-01                (K8s control plane - needs ingress for routing)
10. k3s-02, k3s-03       (K8s workers - after control plane)
11. nick-vm              (dev workstation - last, lowest priority)
```

**Why this order?**

- **Observability first**: See logs/metrics as you deploy everything else
- **Storage early**: Other services depend on it
- **Ingress before services**: Services can be public immediately
- **K8s last**: Most complex, depends on ingress

---

## Phase 3: Deployment Runbook

### For Each Host (Follow This Pattern):

#### Step 1: Create VM in Proxmox

**Specs** (adjust per host):

| Host | vCPU | RAM | Disk | Network | IP |
|------|------|-----|------|---------|-----|
| observability-01 | 4 | 4GB | 40GB | vmbr0 | 10.0.0.30 |
| storage-backup-01 | 2 | 2GB | 100GB | vmbr0 | 10.0.2.118 |
| storage-media-01 | 2 | 2GB | 100GB | vmbr0 | 10.0.0.16 |
| ingress-01 | 2 | 2GB | 20GB | vmbr0 | 10.0.0.11 |
| netbox-01 | 2 | 4GB | 40GB | vmbr0 | 10.0.0.10 |
| pxe-01 | 2 | 2GB | 20GB | vmbr0 | DHCP |
| jellyfin-01 | 4 | 4GB | 30GB | vmbr0 | DHCP |
| mediamtx-01 | 2 | 2GB | 20GB | vmbr0 | 10.0.0.13 |
| k3s-01 | 4 | 8GB | 50GB | vmbr0 | 10.0.0.31 |
| k3s-02 | 4 | 8GB | 50GB | vmbr0 | 10.0.0.32 |
| k3s-03 | 4 | 8GB | 50GB | vmbr0 | 10.0.0.33 |

#### Step 2: Install Minimal NixOS

Boot from NixOS ISO, install basic system:

```bash
# Partition (UEFI)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# Format
mkfs.fat -F 32 -n EFI /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# Mount
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# Generate config
nixos-generate-config --root /mnt

# Edit /mnt/etc/nixos/configuration.nix
# - Enable SSH
# - Add your SSH key
# - Set hostname

# Install
nixos-install
reboot
```

#### Step 3: Bootstrap Age Key

```bash
# SSH into new host
ssh root@HOST-IP

# Generate age key
mkdir -p /var/lib/sops-nix
nix-shell -p age --run "age-keygen -o /var/lib/sops-nix/key.txt"
chmod 600 /var/lib/sops-nix/key.txt

# Get public key
nix-shell -p age --run "age-keygen -y /var/lib/sops-nix/key.txt"
# Copy output (age1...)
```

#### Step 4: Update Secrets Config

```bash
# On your laptop
cd ~/dev/infrastructure/flakes

# Add public key to .sops.yaml
# (append to age: list)

# Rekey secrets
sops updatekeys secrets/prod.yaml

# Commit
git add .sops.yaml secrets/prod.yaml
git commit -m "Add age key for HOST-NAME"
```

#### Step 5: Deploy from Flake

```bash
# From a Linux VM (or Proxmox host)
cd /path/to/flakes
git pull

# Deploy
nixos-rebuild switch \
  --flake .#HOST-NAME \
  --target-host root@HOST-IP
```

#### Step 6: Verify

```bash
# Check services
ssh root@HOST-IP
systemctl status nginx  # or other services
journalctl -u SERVICE -f

# Check secrets
ls -l /run/secrets/

# Check monitoring (from observability-01)
curl http://observability-01:9090/targets
```

---

## Phase 4: Deployment Scripts

### Automation Helper

Create `scripts/deploy-all.sh` to track progress:

```bash
#!/usr/bin/env bash
set -euo pipefail

HOSTS=(
  "observability-01:10.0.0.30"
  "storage-backup-01:10.0.2.118"
  "storage-media-01:10.0.0.16"
  "ingress-01:10.0.0.11"
  "netbox-01:10.0.0.10"
  "pxe-01:DHCP"
  "jellyfin-01:DHCP"
  "mediamtx-01:10.0.0.13"
  "k3s-01:10.0.0.31"
  "k3s-02:10.0.0.32"
  "k3s-03:10.0.0.33"
)

echo "=== NixOS Infrastructure Deployment ==="
echo ""
echo "Hosts to deploy (in order):"
for host in "${HOSTS[@]}"; do
  echo "  - ${host%:*} (${host#*:})"
done
echo ""

read -p "Proceed with deployment? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

for host_spec in "${HOSTS[@]}"; do
  HOST="${host_spec%:*}"
  IP="${host_spec#*:}"

  echo ""
  echo "=== Deploying $HOST ($IP) ==="

  if [[ "$IP" == "DHCP" ]]; then
    read -p "Enter IP for $HOST: " IP
  fi

  read -p "Press Enter to deploy $HOST, or Ctrl-C to skip..."

  nixos-rebuild switch \
    --flake .#"$HOST" \
    --target-host root@"$IP" \
    --build-host localhost || {
    echo "FAILED: $HOST"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
  }

  echo "SUCCESS: $HOST deployed"
done

echo ""
echo "=== Deployment Complete ==="
```

---

## Phase 5: Post-Deployment Verification

### Checklist for Each Host

- [ ] Host boots and is SSH accessible
- [ ] All systemd services are running
- [ ] Secrets decrypted successfully (`ls /run/secrets/`)
- [ ] Prometheus scraping metrics (check observability-01)
- [ ] Logs shipping to Loki
- [ ] Firewall configured correctly
- [ ] Tailscale connected (if applicable)

### Infrastructure-Level Verification

1. **Observability Stack**:
   ```bash
   # Check Prometheus targets
   curl http://observability-01:9090/targets

   # Check Grafana
   curl http://observability-01:3000

   # Query Loki
   curl http://observability-01:3100/ready
   ```

2. **Ingress Routing**:
   ```bash
   # Test each service through ingress
   curl -H "Host: netbox.local" http://10.0.0.11/api/status/
   curl -H "Host: media.local" http://10.0.0.11/
   curl -H "Host: observability.local" http://10.0.0.11/
   ```

3. **Storage**:
   ```bash
   # Verify NFS exports
   showmount -e storage-media-01

   # Test mount from jellyfin-01
   ssh jellyfin-01 "df -h | grep media"
   ```

4. **K8s Cluster**:
   ```bash
   # Check nodes
   kubectl get nodes

   # Check pods
   kubectl get pods -A

   # Test ingress routing (if deployed)
   curl https://demo.k8s.betatechnology.org
   ```

---

## Phase 6: Cloudflare & Public Access

### After ingress-01 is deployed:

1. **Create Cloudflare Tunnel** (if not done already)
2. **Add tunnel credentials to secrets**:
   ```bash
   sops secrets/prod.yaml
   # Add cloudflared-beta-creds
   ```
3. **Redeploy ingress-01**:
   ```bash
   nixos-rebuild switch --flake .#ingress-01 --target-host root@10.0.0.11
   ```
4. **Update DNS**: Point `*.betatechnology.org` to tunnel

---

## Emergency Rollback Plan

If a deployment breaks critical services:

### Option 1: Rollback Single Host

```bash
# SSH into broken host
ssh root@HOST

# Rollback to previous generation
nixos-rebuild --rollback switch

# Or boot into previous generation via GRUB
# (accessible via Proxmox console)
```

### Option 2: Keep Old VMs Alive During Migration

**Safer approach**:
1. Don't delete old VMs immediately
2. Deploy new VMs with different IPs
3. Test new VMs thoroughly
4. Only after verification, delete old VMs and reassign IPs

**Example**:
```
Old: netbox-01 (10.0.0.10)
New: netbox-01-new (10.0.0.50) ← Deploy here first
Test thoroughly
Then: Delete old, rename new, reassign IP
```

### Option 3: Snapshot Before Each Deployment

```bash
# From Proxmox, before deploying to a host
qm snapshot <VMID> pre-deploy-$(date +%Y%m%d-%H%M)

# If deployment breaks, restore snapshot
qm rollback <VMID> pre-deploy-TIMESTAMP
```

---

## Timeline Estimate

**Conservative estimate** (1 person, methodical approach):

| Phase | Duration | Notes |
|-------|----------|-------|
| Phase 0: Prep & Backup | 2-4 hours | Critical - don't rush |
| Phase 1: Teardown | 30 min | Fast if backups done |
| Phase 2-3: Deploy observability-01 | 1-2 hours | First deployment, test process |
| Deploy storage hosts (2) | 2-3 hours | storage-backup, storage-media |
| Deploy ingress-01 | 1-2 hours | Including Cloudflare setup |
| Deploy core services (2) | 2-3 hours | netbox, pxe |
| Deploy media stack (2) | 2-3 hours | jellyfin, mediamtx |
| Deploy K8s cluster (3) | 4-6 hours | k3s-01, k3s-02, k3s-03 + testing |
| Deploy workstations (1) | 1 hour | nick-vm |
| **Total** | **18-28 hours** | Spread over 2-3 days |

**Aggressive timeline** (if everything goes smoothly): 1 full day
**Realistic timeline**: 2-3 days with testing and troubleshooting

---

## Questions Before You Start

1. **Do you have production data that needs backing up?**
   - Netbox database?
   - Media files?
   - Any critical data on current VMs?

2. **Can you afford downtime?**
   - Is this a production environment?
   - Do you need to keep old VMs alive during migration?

3. **Do you have console access to Proxmox?**
   - Critical for fixing broken deployments

4. **Which host should be your build host?**
   - Proxmox host itself?
   - An existing Linux machine?
   - Should I set up remote builder config?

5. **Do you want to do this in stages or all at once?**
   - Stage 1: Observability + Storage
   - Stage 2: Ingress + Core services
   - Stage 3: Media + K8s
   - Or: Full rebuild in one session?

---

## My Recommendation

**Hybrid Approach**:

1. **Keep observability-01 if it's working** - Don't lose monitoring
2. **Deploy new hosts one at a time** - Test each thoroughly
3. **Start with ingress-01** - It's the foundation for your new architecture
4. **Leave K8s for last** - Most complex, can be added later

**Or**, if you're confident:

**Full rebuild in deployment order** - Clean slate, but higher risk. Make sure you have good backups and console access.

---

**What do you want to do?** I can guide you through whichever approach you choose.
