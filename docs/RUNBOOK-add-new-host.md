# Runbook: Adding a New NixOS Host with SOPS Secrets

**Purpose**: Step-by-step process for deploying a new NixOS host with encrypted secrets
**Applies to**: Any new host defined in `inventories/prod.nix`
**Last Updated**: 2025-01-06

---

## Prerequisites

- [ ] Host defined in `inventories/prod.nix`
- [ ] Role and host module created
- [ ] VM provisioned in Proxmox
- [ ] Access to a Linux machine for deployment (nick-vm, netbox-01, or Proxmox host)

---

## Phase 1: Initial NixOS Installation

### Step 1.1: Boot NixOS Installer

1. **Attach NixOS ISO** to VM in Proxmox
2. **Boot** from ISO
3. **Verify network**: `ping 1.1.1.1`

### Step 1.2: Partition and Format Disk

**For UEFI systems** (most VMs):

```bash
# Partition
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
```

### Step 1.3: Generate Minimal Config

```bash
nixos-generate-config --root /mnt
```

### Step 1.4: Edit Configuration

Edit `/mnt/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "NEW-HOST-NAME";
  networking.useDHCP = true;

  # SSH
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes"; # Temporary, for bootstrap

  # User (temporary, will be replaced by flake config)
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... your-key-here"
  ];

  # Allow unfree (if needed)
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11";
}
```

### Step 1.5: Install

```bash
nixos-install

# Set root password when prompted
# Or: nixos-install --no-root-passwd

reboot
```

---

## Phase 2: Bootstrap Age Key

### Step 2.1: SSH into New Host

```bash
ssh root@NEW-HOST-IP
```

### Step 2.2: Generate Age Key

```bash
# Create directory
mkdir -p /var/lib/sops-nix
chmod 700 /var/lib/sops-nix

# Generate key
nix-shell -p age --run "age-keygen -o /var/lib/sops-nix/key.txt"

# Secure permissions
chmod 600 /var/lib/sops-nix/key.txt
chown root:root /var/lib/sops-nix/key.txt
```

### Step 2.3: Extract Public Key

```bash
nix-shell -p age --run "age-keygen -y /var/lib/sops-nix/key.txt"
```

**Copy the output** (looks like `age1...`). This is the **public key**.

### Step 2.4: Backup Private Key (Optional but Recommended)

```bash
# Display private key
cat /var/lib/sops-nix/key.txt
```

**Store this securely offline** (password manager, encrypted USB, etc.).
⚠️ **NEVER commit this to git!**

---

## Phase 3: Update Secrets Configuration

**On your development machine** (Mac or Linux):

### Step 3.1: Add Public Key to SOPS Config

Edit `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: ^secrets/prod\.ya?ml$
    age: >-
      age1ycfwrad25wrjguqx4um7mck9s0xxc90dd4uytcz68wz2kcf3n4gqjejqhz,
      age1fzfm3rtt7pz53c95dvcup3fwh6gfdmupjgvt6wlsxg333fhzt3vshq6l5f,
      age12yta7yn8cc7c9nqwnvlhkhlywzvtgup0fnsu662sgkcg93grc9eqtrz7pq,
      age1NEW_HOST_PUBLIC_KEY_HERE
```

Add the new host's public key (from Step 2.3) to the comma-separated list.

### Step 3.2: Rekey All Secrets

This re-encrypts all secrets so the new host can decrypt them:

```bash
sops updatekeys secrets/prod.yaml
```

**Verify**: File should have been modified (check `git diff`).

### Step 3.3: Commit Changes

```bash
git add .sops.yaml secrets/prod.yaml
git commit -m "Add age key for NEW-HOST-NAME"
git push
```

---

## Phase 4: Deploy from Flake

**From a Linux machine** (nick-vm, netbox-01, or Proxmox host):

### Step 4.1: Pull Latest Changes

```bash
cd /path/to/infrastructure/flakes
git pull
```

### Step 4.2: Build Configuration

```bash
# Test build first
nix build .#nixosConfigurations.NEW-HOST-NAME.config.system.build.toplevel
```

**Fix any errors** before deploying.

### Step 4.3: Deploy to Host

```bash
# Deploy and activate
nixos-rebuild switch \
  --flake .#NEW-HOST-NAME \
  --target-host root@NEW-HOST-IP \
  --build-host localhost

# Or using wrapper script:
nix run .#nixos-deploy -- NEW-HOST-NAME -H root@NEW-HOST-IP
```

### Step 4.4: Verify Services

```bash
# SSH into host
ssh root@NEW-HOST-IP

# Check critical services
systemctl status nginx
systemctl status cloudflared

# Verify secrets are decrypted
ls -l /run/secrets/
cat /run/secrets/cloudflared-beta-creds  # Should show JSON, not encrypted data
```

---

## Phase 5: Final Hardening

### Step 5.1: Disable Root SSH Login

After verifying `nbg` user works:

```bash
# From the host
systemctl restart sshd

# Verify nbg user can sudo
su - nbg
sudo -i
```

**In the host config**, root SSH is already disabled by `profiles/base.nix`.

### Step 5.2: Verify Tailscale

```bash
# Check Tailscale status
sudo tailscale status

# Verify SSH only on tailscale0
sudo ss -tlnp | grep :22
```

### Step 5.3: Test Rollback

```bash
# From the host
nixos-rebuild --rollback switch

# Verify system still works
# Then switch back to current generation if needed
```

---

## Troubleshooting

### Secret Decryption Fails

**Symptom**: Service fails with "could not decrypt"

**Solution**:
```bash
# Verify age key exists
ls -l /var/lib/sops-nix/key.txt

# Verify public key in .sops.yaml
age-keygen -y /var/lib/sops-nix/key.txt
# Compare with .sops.yaml

# Rekey secrets again
sops updatekeys secrets/prod.yaml

# Redeploy
nixos-rebuild switch --flake .#NEW-HOST-NAME
```

### Service Won't Start (Missing Secret)

**Symptom**: `systemctl status SERVICE` shows "failed to start"

**Solution**:
```bash
# Check which secret is missing
journalctl -u SERVICE -n 50

# Verify secret exists in secrets/prod.yaml
sops -d secrets/prod.yaml | grep SECRET_NAME

# Verify secret is defined in host config
grep "sops.secrets" /etc/nixos/configuration.nix
```

### Age Key Lost / VM Destroyed

**Solution**:
```bash
# Option 1: Restore from backup (if you saved it)
mkdir -p /var/lib/sops-nix
echo "AGE-SECRET-KEY-1..." > /var/lib/sops-nix/key.txt
chmod 600 /var/lib/sops-nix/key.txt

# Option 2: Generate new key, rotate secrets
# Follow Phase 2-3 again
# Remove old public key from .sops.yaml
# Rekey secrets
```

---

## Checklist Template

**Use this for each new host:**

```markdown
## Adding HOST-NAME

- [ ] Phase 1: NixOS installed on VM
  - [ ] Disk partitioned and formatted
  - [ ] Config generated and edited
  - [ ] NixOS installed successfully
  - [ ] VM rebooted and accessible via SSH

- [ ] Phase 2: Age key bootstrapped
  - [ ] Age key generated at /var/lib/sops-nix/key.txt
  - [ ] Public key extracted
  - [ ] Private key backed up securely (optional)

- [ ] Phase 3: Secrets updated
  - [ ] Public key added to .sops.yaml
  - [ ] Secrets rekeyed with `sops updatekeys`
  - [ ] Changes committed and pushed

- [ ] Phase 4: Flake deployed
  - [ ] Configuration builds successfully
  - [ ] Deployed to host
  - [ ] All services running
  - [ ] Secrets accessible at /run/secrets/

- [ ] Phase 5: Hardened
  - [ ] Root SSH disabled (nbg user works)
  - [ ] Tailscale connected
  - [ ] SSH only on tailscale0
  - [ ] Rollback tested

- [ ] Monitoring configured
  - [ ] Prometheus scraping metrics
  - [ ] Logs shipping to Loki
  - [ ] Alerts configured
```

---

## Security Notes

### What Goes in Git ✅
- Public age keys (in `.sops.yaml`)
- Encrypted secrets (in `secrets/prod.yaml`)
- Host configurations
- Role definitions

### What NEVER Goes in Git ❌
- Private age keys (`/var/lib/sops-nix/key.txt`)
- Decrypted secrets
- Cloudflare credentials JSON (unless encrypted with SOPS)
- SSH private keys

### Key Rotation

If a host is compromised:

1. **Remove public key** from `.sops.yaml`
2. **Rekey all secrets**: `sops updatekeys secrets/prod.yaml`
3. **Redeploy all other hosts** (they pick up re-encrypted secrets)
4. **Destroy compromised host**

---

## Related Documentation

- SOPS-nix official docs: https://github.com/Mic92/sops-nix
- Age encryption: https://github.com/FiloSottile/age
- NixOS manual: https://nixos.org/manual/nixos/stable/

---

**Last Reviewed**: 2025-01-06
**Maintained By**: Infrastructure Team
