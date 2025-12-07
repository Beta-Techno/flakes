# Zero to Production: Clean Infrastructure Build

**Status**: Ready to Execute
**Starting Point**: Empty Proxmox, no existing VMs
**Goal**: Deploy dream architecture in optimal order

---

## Pre-Flight: Clean the Repo (5 minutes)

### Step 1: Clean Age Keys

Edit `.sops.yaml` - **remove all host keys**, keep only your admin keys:

```yaml
creation_rules:
  - path_regex: ^secrets/prod\.ya?ml$
    age: >-
      age1ycfwrad25wrjguqx4um7mck9s0xxc90dd4uytcz68wz2kcf3n4gqjejqhz,
      age1fzfm3rtt7pz53c95dvcup3fwh6gfdmupjgvt6wlsxg333fhzt3vshq6l5f
```

(Only include keys you have the private keys for on your Mac or secure backup)

### Step 2: Rekey Secrets

```bash
cd /Users/nbend/dev/infrastructure/flakes
sops updatekeys secrets/prod.yaml
```

### Step 3: Commit Clean State

```bash
git add .sops.yaml secrets/prod.yaml
git commit -m "Clean age keys for fresh deployment"
git push
```

**You're ready.** Now let's deploy.

---

## Deployment Order (The Critical Path)

Build in this order:

```
Day 1 (Foundation):
  1. observability-01  ← Deploy FIRST (eyes on everything)
  2. storage-media-01  ← NFS for media services
  3. ingress-01        ← Front door for HTTP(S)

Day 2 (Services):
  4. netbox-01         ← IPAM/documentation
  5. jellyfin-01       ← Media server
  6. mediamtx-01       ← Streaming

Day 3 (Advanced - Optional):
  7. k3s-01            ← Kubernetes (if you want it)
  8. pxe-01            ← Network boot (if needed)
  9. storage-backup-01 ← Backups (after services exist)
```

**Focus**: Get Day 1 working perfectly. Everything else builds on that foundation.

---

## HOST 1: observability-01 (The Foundation)

**Why first?** You'll see logs and metrics from every other host as you deploy them.

### 1.1: Create VM in Proxmox

**Specs**:
- Name: `observability-01`
- CPU: 4 cores
- RAM: 4GB
- Disk: 40GB
- Network: vmbr0
- Boot: Attach NixOS ISO

### 1.2: Install Minimal NixOS

Boot the VM from NixOS ISO, then:

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
```

Edit `/mnt/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "observability-01";
  networking.useDHCP = true;

  # SSH
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Your SSH key
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... your-key-here"  # REPLACE THIS
  ];

  # User
  users.users.nbg = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA... your-key-here"  # REPLACE THIS
    ];
  };

  # Sudo without password (temporary)
  security.sudo.wheelNeedsPassword = false;

  # Essential packages for deployment
  environment.systemPackages = with pkgs; [
    git vim curl wget age
  ];

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11";
}
```

Install:

```bash
nixos-install
reboot
```

### 1.3: Bootstrap Age Key

After reboot, SSH in:

```bash
# From your Mac
ssh root@<OBSERVABILITY-IP>

# Generate age key
mkdir -p /var/lib/sops-nix
age-keygen -o /var/lib/sops-nix/key.txt
chmod 600 /var/lib/sops-nix/key.txt

# Get public key
age-keygen -y /var/lib/sops-nix/key.txt
```

**Copy the output** (age1...) - this is the public key.

### 1.4: Update Secrets Config

On your Mac:

```bash
cd /Users/nbend/dev/infrastructure/flakes

# Edit .sops.yaml - add the observability-01 public key
# Should look like:
# age: >-
#   age1ycfwrad...,
#   age1fzfm3r...,
#   age1OBSERVABILITY_PUBLIC_KEY_HERE

# Rekey secrets
sops updatekeys secrets/prod.yaml

# Commit
git add .sops.yaml secrets/prod.yaml
git commit -m "Add observability-01 age key"
git push
```

### 1.5: Clone Flake Repo on observability-01

```bash
# Still SSH'd into observability-01
su - nbg
cd ~
git clone https://github.com/YOUR-USERNAME/infrastructure flakes
cd flakes
```

**Or** if you prefer to deploy from another Linux VM, that's fine too.

### 1.6: Deploy Flake Config

```bash
# From observability-01 (as nbg user)
cd ~/flakes

# Build and deploy
sudo nixos-rebuild switch --flake .#observability-01

# This will:
# - Install Prometheus, Loki, Grafana
# - Configure nginx reverse proxy
# - Set up observability stack
# - Enable node exporter
```

**Wait 5-10 minutes** for first build (lots of packages).

### 1.7: Verify

```bash
# Check services
sudo systemctl status prometheus
sudo systemctl status loki
sudo systemctl status grafana
sudo systemctl status nginx

# Check web interface (from your Mac browser)
# Replace IP with actual observability-01 IP
open http://<OBSERVABILITY-IP>/       # Grafana
open http://<OBSERVABILITY-IP>/prometheus/  # Prometheus
```

**Login to Grafana**:
- URL: `http://<IP>/`
- User: `admin`
- Password: Check `secrets/prod.yaml` for `grafana-admin-password`

**Success criteria**:
- ✅ All systemd services running
- ✅ Grafana web UI loads
- ✅ Prometheus web UI loads
- ✅ No errors in `journalctl -xe`

---

## HOST 2: storage-media-01 (NFS for Media)

**Why second?** Jellyfin and MediaMTX will mount NFS from here.

### 2.1: Create VM

**Specs**:
- Name: `storage-media-01`
- CPU: 2 cores
- RAM: 2GB
- Disk: **100GB** (or larger for media)
- Network: vmbr0

### 2.2: Install NixOS (Same Process as observability-01)

- Boot from ISO
- Partition disk (same commands)
- `nixos-generate-config --root /mnt`
- Edit config (hostname: `storage-media-01`)
- `nixos-install`, `reboot`

### 2.3: Bootstrap Age Key

```bash
ssh root@<STORAGE-MEDIA-IP>
mkdir -p /var/lib/sops-nix
age-keygen -o /var/lib/sops-nix/key.txt
age-keygen -y /var/lib/sops-nix/key.txt  # Copy public key
```

### 2.4: Update Secrets & Deploy

```bash
# On your Mac
cd ~/dev/infrastructure/flakes
# Add storage-media-01 public key to .sops.yaml
sops updatekeys secrets/prod.yaml
git commit -am "Add storage-media-01 age key"
git push

# On observability-01 (or storage-media-01 itself)
cd ~/flakes
git pull
sudo nixos-rebuild switch --flake .#storage-media-01 --target-host root@<STORAGE-MEDIA-IP>
```

### 2.5: Verify NFS

```bash
# From observability-01 or your Mac
showmount -e <STORAGE-MEDIA-IP>

# Should show:
# /srv/media 10.0.0.0/24,10.0.2.0/24
```

**Success**: NFS export visible.

---

## HOST 3: ingress-01 (The Front Door)

**Why third?** Now you have monitoring (observability) and can expose services publicly.

### 3.1: Create Cloudflare Tunnel (Before VM)

1. Login to **Cloudflare Zero Trust**: https://one.dash.cloudflare.com/
2. Navigate to **Networks → Tunnels**
3. Click **Create a tunnel**
4. Name: `beta-ingress`
5. Download **credentials JSON**

### 3.2: Add Credentials to Secrets

```bash
cd ~/dev/infrastructure/flakes
sops secrets/prod.yaml
```

Add this entry (paste your actual JSON):

```yaml
cloudflared-beta-creds: |
  {
    "AccountTag": "your-account-tag",
    "TunnelID": "your-tunnel-id",
    "TunnelSecret": "your-tunnel-secret"
  }
```

Save and exit.

```bash
git commit -am "Add Cloudflare tunnel credentials"
git push
```

### 3.3: Create VM & Install NixOS

**Specs**:
- Name: `ingress-01`
- CPU: 2 cores
- RAM: 2GB
- Disk: 20GB
- Network: vmbr0
- **Static IP or DHCP reservation**: `10.0.0.11` (recommended)

Follow same NixOS install process as before.

### 3.4: Bootstrap Age Key & Deploy

```bash
# On ingress-01
mkdir -p /var/lib/sops-nix
age-keygen -o /var/lib/sops-nix/key.txt
age-keygen -y /var/lib/sops-nix/key.txt  # Copy public key

# On your Mac
# Add ingress-01 public key to .sops.yaml
sops updatekeys secrets/prod.yaml
git commit -am "Add ingress-01 age key"
git push

# Deploy (from observability-01 or ingress-01 itself)
cd ~/flakes
git pull
sudo nixos-rebuild switch --flake .#ingress-01 --target-host root@10.0.0.11
```

### 3.5: Configure DNS

In Cloudflare, create CNAME records:

| Hostname | Type | Target |
|----------|------|--------|
| netbox.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |
| obs.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |
| media.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |
| stream.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |
| *.k8s.betatechnology.org | CNAME | `<tunnel-id>.cfargotunnel.com` |

### 3.6: Verify Ingress

```bash
# Check services
ssh root@10.0.0.11
systemctl status nginx
systemctl status cloudflared

# Test routing to observability (from your Mac)
curl -H "Host: observability.local" http://10.0.0.11/

# Test public access via Cloudflare
curl https://obs.betatechnology.org/
```

**Success**: Nginx running, Cloudflare tunnel connected, routing works.

---

## After Day 1: You Have the Foundation

At this point you have:

✅ **Observability** - Prometheus/Loki/Grafana monitoring everything
✅ **Storage** - NFS ready for media services
✅ **Ingress** - Single front door with Cloudflare tunnel

**From here**, deploy remaining hosts following the same pattern:

1. Create VM
2. Install minimal NixOS
3. Bootstrap age key → add to .sops.yaml → rekey
4. Deploy from flake
5. Verify

---

## Remaining Hosts (Day 2+)

### netbox-01
- Specs: 2 CPU, 4GB RAM, 40GB disk
- IP: 10.0.0.10
- Role: `netbox`
- Verify: `curl http://10.0.0.10/api/status/`

### jellyfin-01
- Specs: 4 CPU, 4GB RAM, 30GB disk
- IP: DHCP (or 10.0.0.12)
- Role: `jellyfin-lite`
- Mounts: `/mnt/media` from storage-media-01
- Verify: `curl http://<IP>:8096/`

### mediamtx-01
- Specs: 2 CPU, 2GB RAM, 20GB disk
- IP: 10.0.0.13
- Role: `mediamtx-lite`
- Verify: `curl http://10.0.0.13:8888/`

### k3s-01 (Optional - K8s)
- Specs: 4 CPU, 8GB RAM, 50GB disk
- IP: 10.0.0.31
- Role: `k3s`
- Verify: `kubectl get nodes`

---

## Deployment Checklist

Use this to track progress:

```
Foundation (Day 1):
  [ ] observability-01
      [ ] VM created
      [ ] NixOS installed
      [ ] Age key bootstrapped
      [ ] Config deployed
      [ ] Grafana accessible
      [ ] Prometheus scraping itself

  [ ] storage-media-01
      [ ] VM created
      [ ] NixOS installed
      [ ] Age key bootstrapped
      [ ] Config deployed
      [ ] NFS exports visible
      [ ] Prometheus scraping

  [ ] ingress-01
      [ ] VM created
      [ ] NixOS installed
      [ ] Age key bootstrapped
      [ ] Cloudflare tunnel created
      [ ] Credentials in secrets
      [ ] Config deployed
      [ ] Nginx running
      [ ] Cloudflare tunnel connected
      [ ] DNS configured
      [ ] Routes to observability working

Services (Day 2):
  [ ] netbox-01
  [ ] jellyfin-01
  [ ] mediamtx-01

Advanced (Day 3+):
  [ ] k3s-01
  [ ] pxe-01
  [ ] storage-backup-01
```

---

## Quick Reference Commands

### Deploy a host
```bash
# From observability-01 (or any Linux VM with the flake repo)
cd ~/flakes
git pull
sudo nixos-rebuild switch --flake .#HOST-NAME --target-host root@HOST-IP
```

### Check monitoring
```bash
# Prometheus targets
curl http://observability-01:9090/targets

# Grafana (in browser)
open http://observability-01:3000/
```

### Troubleshoot deployment
```bash
# On the target host
journalctl -xe
systemctl list-units --failed
systemctl status SERVICE-NAME
```

### Verify secrets
```bash
ls -l /run/secrets/
cat /run/secrets/cloudflared-beta-creds  # Should show JSON
```

---

## What to Do Right Now

1. **Clean .sops.yaml** (remove old host keys)
2. **Rekey secrets**: `sops updatekeys secrets/prod.yaml`
3. **Commit**: `git commit -am "Clean slate for fresh deployment"`
4. **Create observability-01 VM** in Proxmox
5. **Boot NixOS ISO** and start install

**Follow the guide step-by-step.** Don't rush. Each host takes 1-2 hours first time, faster after you learn the pattern.

---

**You're ready to build.** Let's deploy the dream system. 🚀
