# K3s Kubernetes role - designed to work with dedicated ingress-01 VM
{ config, lib, pkgs, cfg, ... }:

let
  # Values are passed from inventories/<env>.nix as cfg.k3s = { ... };
  k                  = cfg.k3s or {};
  kRole              = (k.role or "server");     # "server" | "agent"
  kServerAddr        = (k.serverAddr or null);   # e.g. "https://10.0.0.31:6443"
  kClusterInit       = (k.clusterInit or (kRole == "server"));
  disableTraefik     = (k.disableTraefik or true);  # Default true since we have ingress-01
  disableServiceLB   = (k.disableServiceLB or false);
in {
  imports = [
    ../profiles/base.nix
    ../profiles/virt.nix
    ../profiles/sops.nix
  ];

  assertions = [
    {
      assertion = !(kRole != "server" && (kServerAddr == null));
      message   = "k3s agent requires cfg.k3s.serverAddr in the inventory.";
    }
  ];

  # k3s (lightweight Kubernetes)
  services.k3s = {
    enable     = true;
    role       = if kRole == "server" then "server" else "agent";
    clusterInit = lib.mkIf (kRole == "server") kClusterInit;

    # Token delivered by sops-nix (kept off the Nix store)
    tokenFile  = config.sops.secrets."k3s-token".path;

    # Only agents need to know where the server is
    serverAddr = lib.mkIf (kRole != "server") kServerAddr;

    # Disable Traefik by default since we have dedicated ingress-01
    # Keep servicelb for now (can be disabled later when we add MetalLB)
    extraFlags =
      (lib.optionals disableServiceLB [ "--disable=servicelb" ]) ++
      (lib.optionals disableTraefik  [ "--disable=traefik"  ]);

    # Optional: add manifests declaratively here
    # manifests."namespace-demo.yaml".text = ''
    #   apiVersion: v1
    #   kind: Namespace
    #   metadata: { name: demo }
    # '';
  };

  # Open only what k3s/flannel typically needs
  # Note: 80/443 not opened since we have dedicated ingress-01
  networking.firewall.allowedTCPPorts = [ 22 6443 ];
  networking.firewall.allowedUDPPorts = [ 8472 ];  # flannel VXLAN

  # Do not enable Docker on k3s nodes (k3s uses containerd)
  virtualisation.docker.enable = lib.mkDefault false;

  # Kubernetes tools
  environment.systemPackages = with pkgs; [ 
    kubectl 
    k9s 
    helm 
    kustomize
    kubernetes-helm
  ];

  # Optional: add a local admin user for kubectl access
  users.users.k3s-admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = lib.mkIf 
      (builtins.pathExists ../../keys/users/nbg.pub)
      [ (builtins.readFile ../../keys/users/nbg.pub) ];
  };
}
