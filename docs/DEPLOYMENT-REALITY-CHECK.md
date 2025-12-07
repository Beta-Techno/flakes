# Deployment Reality Check: First Principles Analysis

**Date**: 2025-01-06
**Status**: Critical Issues Identified
**Recommendation**: Address blockers before attempting deployment

---

## TL;DR: We Have Problems

I reviewed the deployment process from first principles and found **critical blockers**:

1. ❌ **Can't build from macOS**: You're on Apple Silicon (arm64), need x86_64-linux builds
2. ❌ **No remote builders configured**: Nix doesn't know how to cross-compile
3. ⚠️ **SOPS chicken-and-egg**: Host age keys generated on first boot, but we need them to decrypt secrets
4. ⚠️ **No staging environment**: Deploying directly to production is risky
5. ⚠️ **nixos-deploy won't work from macOS**: Script expects local NixOS with sudo

**Bottom line**: The deployment guide I wrote assumes you're deploying from a Linux machine. We need a different strategy for macOS.

---

## Current Reality

### Your Setup
- **Laptop**: Apple Silicon Mac (arm64) running macOS 15.6.1
- **Target**: x86_64-linux NixOS VMs in Proxmox
- **Nix config**: No remote builders configured
- **Deployment tool**: `nixos-deploy` script (expects Linux + sudo)

### What the Deployment Guide Assumed
```bash
# This won't work from macOS:
nix run .#nixos-deploy -- ingress-01 -H root@10.0.0.11
```

**Why it fails**:
1. `nixos-deploy` calls `sudo nixos-rebuild` (no sudo on macOS, wrong OS)
2. Builds x86_64-linux packages (your Mac is arm64)
3. No remote builder to cross-compile

---

## The Chicken-and-Egg Problems

### Problem 1: Building from macOS

**Current state**:
```bash
$ uname -m
arm64

$ nix build .#nixosConfigurations.ingress-01.config.system.build.toplevel
error: a 'x86_64-linux' with features {} is required to build '...',
but I am a 'aarch64-darwin' with features {...}
```

**Solutions** (pick one):

**A. Use existing Linux VM as builder** (RECOMMENDED)
```bash
# On your Mac, configure netbox-01 or nick-vm as remote builder
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf <<EOF
builders = ssh://nbg@10.0.0.21 x86_64-linux - 8 1 big-parallel
builders-use-substitutes = true
EOF

# Test it
nix build .#nixosConfigurations.ingress-01.config.system.build.toplevel \
  --builders 'ssh://nbg@10.0.0.21 x86_64-linux'
```

**B. Use GitHub Actions / CI** (for automation later)
- Build on GitHub runners
- Push to Cachix or binary cache
- Deploy pre-built artifacts

**C. Deploy from Linux VM**
- SSH into nick-vm or netbox-01
- Clone flake repo there
- Run `nixos-deploy` from Linux

**D. Use nixos-anywhere** (cleanest, but different tool)
- Designed for remote deployment from any OS
- Handles installation + deployment in one shot

### Problem 2: SOPS Age Keys

**The chicken-and-egg**:
1. New VM boots → generates age key at `/var/lib/sops-nix/key.txt`
2. You need to add that key to `.sops.yaml`
3. Then rekey all secrets: `sops updatekeys secrets/prod.yaml`
4. Then redeploy with updated secrets

**Current `.sops.yaml` age keys**:
```yaml
age:
  - age1ycfwrad25wrjguqx4um7mck9s0xxc90dd4uytcz68wz2kcf3n4gqjejqhz
  - age1fzfm3rtt7pz53c95dvcup3fwh6gfdmupjgvt6wlsxg333fhzt3vshq6l5f
  - age12yta7yn8cc7c9nqwnvlhkhlywzvtgup0fnsu662sgkcg93grc9eqtrz7pq
  - age12yta7yn8cc7c9nqwnvlhkhlywzvtgup0fnsu662sgkcg93grc9eqtrz7pq
```

**Solutions**:

**A. Bootstrap age key before deployment** (RECOMMENDED)
```bash
# 1. SSH into fresh VM
ssh root@10.0.0.11

# 2. Generate age key
mkdir -p /var/lib/sops-nix
age-keygen -o /var/lib/sops-nix/key.txt
chmod 600 /var/lib/sops-nix/key.txt

# 3. Get public key
age-keygen -y /var/lib/sops-nix/key.txt
# Output: age1...

# 4. On your Mac, add to .sops.yaml
# 5. Rekey secrets: sops updatekeys secrets/prod.yaml
# 6. Deploy
```

**B. Use existing key for initial deployment**
- Create age key on your Mac
- Copy to VM before deployment
- Later regenerate on host

**C. Deploy without secrets first**
- Initial deployment without cloudflared (won't start)
- Bootstrap age key
- Redeploy with secrets

### Problem 3: No Staging Environment

**Risk**: Deploying untested code directly to production ingress.

**What could go wrong**:
- Nginx config syntax error → ingress-01 won't boot
- Wrong backend hostnames → 502 errors for all services
- Cloudflared credentials invalid → tunnel never connects
- Firewall misconfiguration → can't SSH back in

**Solutions**:

**A. Deploy to test VM first** (RECOMMENDED)
```bash
# Create ingress-test VM (same specs as ingress-01)
# Deploy there first
# Test thoroughly
# If good, deploy to production ingress-01
```

**B. Use nixos-rebuild boot instead of switch**
```bash
# Deploy but don't activate
nixos-rebuild boot --flake .#ingress-01 --target-host root@10.0.0.11

# Manual reboot from console (can rollback via grub if broken)
ssh root@10.0.0.11 reboot
```

**C. Keep rescue shell available**
- Deploy via Proxmox console (not SSH)
- If broken, can manually fix via console

---

## Recommended Deployment Strategy (Safe Path)

### Phase 0: Preparation (Your Mac)

1. **Set up remote builder**:
   ```bash
   # Use nick-vm or netbox-01 as builder
   mkdir -p ~/.config/nix
   cat > ~/.config/nix/nix.conf <<EOF
   builders = ssh://nbg@10.0.0.21 x86_64-linux - 8 1 big-parallel
   builders-use-substitutes = true
   EOF

   # Test SSH access
   ssh nbg@10.0.0.21 "nix --version"
   ```

2. **Verify flake builds**:
   ```bash
   cd /Users/nbend/dev/infrastructure/flakes

   # This should now use remote builder
   nix build .#nixosConfigurations.ingress-01.config.system.build.toplevel \
     --print-build-logs

   # Check result
   ls -lh ./result
   ```

3. **Create Cloudflare tunnel** (as documented)

4. **Provision test VM in Proxmox**:
   - Name: `ingress-test`
   - IP: `10.0.0.12` (temporary)
   - Same specs as production

### Phase 1: Install NixOS on Test VM

**From Proxmox console** (not SSH):

```bash
# Boot NixOS minimal ISO
# Partition disk (manual or disko)
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

# Generate minimal config
nixos-generate-config --root /mnt

# Edit /mnt/etc/nixos/configuration.nix:
# - Set networking.hostName = "ingress-test"
# - Enable sshd
# - Add your SSH key
# - Set root password

# Install
nixos-install

# Reboot
reboot
```

### Phase 2: Bootstrap Age Key

**From test VM** (SSH):

```bash
ssh root@10.0.0.12

# Generate age key
mkdir -p /var/lib/sops-nix
nix-shell -p age --run "age-keygen -o /var/lib/sops-nix/key.txt"
chmod 600 /var/lib/sops-nix/key.txt

# Get public key
nix-shell -p age --run "age-keygen -y /var/lib/sops-nix/key.txt"
# Copy this output
```

**On your Mac**:

```bash
# Add to .sops.yaml
# Edit creation_rules.age to include new key

# Rekey secrets
sops updatekeys secrets/prod.yaml

# Commit
git add .sops.yaml secrets/prod.yaml
git commit -m "Add ingress-test age key"
```

### Phase 3: Deploy to Test VM

**From your Mac** (using remote builder):

```bash
# Build configuration
nix build .#nixosConfigurations.ingress-01.config.system.build.toplevel \
  --print-build-logs

# Copy to test VM
nix copy --to ssh://root@10.0.0.12 ./result

# Activate on test VM
ssh root@10.0.0.12 "sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch"

# Or use nixos-rebuild directly (from Mac, using remote builder)
nixos-rebuild switch --flake .#ingress-01 \
  --target-host root@10.0.0.12 \
  --build-host nbg@10.0.0.21
```

### Phase 4: Verify Test VM

```bash
# Check services
ssh root@10.0.0.12 "systemctl status nginx cloudflared"

# Test routing (from LAN)
curl -H "Host: netbox.local" http://10.0.0.12/api/status/

# Test Cloudflare tunnel
# (Point test DNS to test VM tunnel first)
```

### Phase 5: Deploy to Production

**Only after test VM is 100% verified**:

1. Provision production `ingress-01` VM (IP 10.0.0.11)
2. Repeat Phase 1-4 for production
3. Update Cloudflare DNS to production tunnel
4. Decommission Ubuntu VM

---

## Alternative: Use nixos-anywhere (Recommended for Future)

**What is it**: Tool designed for deploying NixOS from any OS (including macOS)

**Advantages**:
- One command: install + deploy
- Works from macOS
- Handles disk partitioning automatically
- No manual NixOS install needed

**Usage**:
```bash
# Install
nix profile install github:nix-community/nixos-anywhere

# Deploy (with disko config)
nixos-anywhere --flake .#ingress-01 root@10.0.0.11
```

**Requirements**:
- Add disko configuration to ingress-01
- VM must be booted into live environment (or have SSH access)

---

## Risk Assessment

### Current Deployment Plan (My Original Guide)

| Risk | Severity | Mitigation |
|------|----------|------------|
| Can't build from macOS | **Critical** | ✅ Use remote builder |
| No staging environment | **High** | ✅ Deploy to test VM first |
| SOPS key missing | **High** | ✅ Bootstrap age key manually |
| Bad nginx config | **Medium** | ⚠️ Syntax check before deploy |
| Wrong DNS | **Medium** | ⚠️ Test with direct IP first |
| Can't SSH back in | **Medium** | ✅ Keep Proxmox console access |
| Cloudflare tunnel fails | **Low** | ✅ Services still work on LAN |

### Recommended Safe Path

| Risk | Severity | Mitigation |
|------|----------|------------|
| Test VM breaks | **Low** | ✅ No production impact |
| Production deploy fails | **Low** | ✅ Rollback via Proxmox console |
| Age key lost | **Low** | ✅ Backed up in .sops.yaml |

---

## What I Should Have Asked You First

Before writing the deployment guide, I should have asked:

1. ❓ **What OS are you deploying from?** (macOS vs Linux)
2. ❓ **Do you have a Linux VM I can use as remote builder?**
3. ❓ **Do you have a staging environment for testing?**
4. ❓ **How do you currently deploy NixOS configs?** (existing workflow)
5. ❓ **Do you want to keep the Ubuntu ingress VM running during testing?**
6. ❓ **Are you comfortable with Proxmox console access if SSH breaks?**

---

## Corrected Next Steps

### Option A: Safe Production Deployment (Recommended)

1. **Set up remote builder** (nick-vm or netbox-01)
2. **Test build locally**: `nix build .#nixosConfigurations.ingress-01...`
3. **Provision test VM** (ingress-test)
4. **Deploy to test VM**, verify thoroughly
5. **Provision production VM** (ingress-01)
6. **Deploy to production**, verify
7. **Update DNS**, monitor
8. **Decommission Ubuntu VM**

**Timeline**: 1-2 days for safe testing

### Option B: YOLO Production Deployment (Not Recommended)

1. Provision ingress-01
2. Manual NixOS install via console
3. Bootstrap age key manually
4. Deploy directly
5. Hope nothing breaks

**Timeline**: 2-4 hours if lucky, days if broken

### Option C: Use nixos-anywhere (Modern Approach)

1. Add disko config to ingress-01
2. Install nixos-anywhere
3. One command deployment
4. Much easier, recommended for future hosts

**Timeline**: 1 hour

---

## Questions for You

Before proceeding:

1. **Do you have a Linux VM I can use as remote builder?** (nick-vm looks promising)
2. **Do you want to test on a separate VM first?** (highly recommended)
3. **Are you comfortable with Proxmox console access?** (needed for rescue)
4. **Do you want me to set up nixos-anywhere instead?** (cleaner for future)
5. **Should I update the deployment docs with the correct macOS workflow?**

---

## Apologies

I should have verified your deployment environment before writing the guide. The guide assumed a Linux deployment host, which doesn't match your reality.

The **code** we wrote (ingress role, host config) is solid. The **deployment process** needs adjustment for macOS.

Let me know which approach you prefer, and I'll create corrected, tested deployment instructions.

---

**Status**: Awaiting your decision on deployment strategy
**Next**: Update docs once we confirm approach
