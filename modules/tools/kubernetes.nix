{ config, pkgs, lib, ... }:

{
  # ── Kubernetes tools ──────────────────────────────────────────
  home.packages = with pkgs; [
    kubectl
    kubectx
    k9s
    kubernetes-helm
    stern
  ];

  # ── Kubernetes shell integration ──────────────────────────────
  programs.zsh.initExtra = ''
    # Kubernetes shell integration
    if [ -f /usr/share/zsh/site-functions/_kubectl ]; then
      source /usr/share/zsh/site-functions/_kubectl
    fi
  '';

  # ── Kubernetes configuration ──────────────────────────────────
  home.file.".kube/config".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.config/kube/config";

  home.shellAliases = {
    k = "kubectl";
    kns = "kubens";
    kctx = "kubectx";
  };
} 