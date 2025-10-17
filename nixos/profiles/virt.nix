{ config, pkgs, lib, ... }:

{
  # ── Virtualization Profile ────────────────────────────────────────────────
  # Common VM configurations for QEMU/KVM, VMware, and VirtualBox guests
  # Import this profile in VM host configurations to get standard VM optimizations

  # Guest tools and optimizations
  services = {
    # QEMU guest agent (for Proxmox/KVM)
    qemuGuest.enable = true;
    
    # Periodic TRIM for SSDs (improves performance and longevity)
    fstrim.enable = true;
  };

  # SPICE agent for better VM integration (optional, can be enabled per host)
  # services.spice-vdagentd.enable = lib.mkDefault false;

  # Virtualization guest tools (disabled by default, enable as needed)
  virtualisation = {
    # VMware guest tools (enable if using VMware)
    vmware.guest.enable = lib.mkDefault false;
    
    # VirtualBox guest tools (enable if using VirtualBox)
    virtualbox.guest.enable = lib.mkDefault false;
  };

  # VM-optimized kernel parameters
  boot = {
    # Load virtual device modules early
    kernelModules = [ "virtio" "virtio_pci" "virtio_net" "virtio_blk" ];
    
    # Make initrd find disk drivers early (prevents boot races)
    initrd.availableKernelModules = [
      "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" "sr_mod"
    ];
    
    # VM-optimized kernel parameters
    kernelParams = [
      "console=tty0"   # VGA console (for Proxmox display)
      "console=ttyS0"  # Serial console (for debugging)
      "nokaslr"
      "iommu=off"
      "libata.force=noncq"  # Reduce ATA spam from virtual devices
      "rootdelay=5"    # Small grace period if udev is slow to create by-label nodes
    ];
  };

  # Hardware configuration for VMs
  hardware = {
    # Enable redistributable firmware for virtual devices
    enableRedistributableFirmware = true;
    
    # Virtual graphics support
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # System optimizations for VM environment
  systemd = {
    # Optimize NetworkManager for VM environment
    services.NetworkManager-wait-online.serviceConfig = {
      ExecStart = [ "" "${pkgs.systemd}/lib/systemd/systemd-networkd-wait-online --any" ];
    };
  };
}
