{ pkgs, lib, ... }:

###############################################################################
#  Rob’s Home-Manager module  (Ubuntu client, Nix 24.05)
#  • Electron apps wrapped with --no-sandbox
#  • JetBrains IDEs run natively
#  • Alacritty runs through nixGLMesa → fixes OpenGL/Wayland crash
#  • targets.genericLinux exposes ~/.nix-profile to GNOME/KDE launchers
###############################################################################

let
  # ──────────────────────────────────────────────────────────────────────────
  # Helpers
  # ──────────────────────────────────────────────────────────────────────────

  # Wrap an Electron app with --no-sandbox
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # Wrap Alacritty so it runs through nixGLMesa (auto-detects Intel/AMD GPUs)
  # First launch builds/downloads nixGLMesa (~80 MB); later launches are instant.
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec nix run --impure github:guibou/nixGL#nixGLMesa -- \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';
in
{
  ########################################
  ## Desktop integration
  ########################################
  targets.genericLinux.enable = true;

  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  ########################################
  ## Packages
  ########################################
  home.packages = with pkgs; [
    # --- CLI tools ---
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # --- Electron apps (wrapped) ---
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode)
    (lib.lowPrio pkgs.postman)

    # --- JetBrains IDEs ---
    jetbrains.datagrip
    jetbrains.rider

    # --- GUI apps ---
    emacs29-pgtk
    alacrittyWrapped
    (lib.lowPrio pkgs.alacritty)   # retains desktop entry
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  ########################################
  ## Shell, Git, Tmux
  ########################################
  programs.zsh = {
    enable            = true;
    oh-my-zsh.enable  = true;
    oh-my-zsh.theme   = "agnoster";
  };

  programs.tmux = {
    enable       = true;
    extraConfig  = ''
      set -g mouse on
      set -g history-limit 100000
    '';
  };

  programs.git = {
    enable     = true;
    userName   = "Rob";
    userEmail  = "rob@example.com";
  };

  home.shellAliases = {
    k   = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };

  fonts.fontconfig.enable = true;

  ########################################
  ## Ghostty terminfo
  ########################################
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
    '';

  ########################################
  ## Cloudflared tunnel (user scope)
  ########################################
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
      Restart   = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  ########################################
  ## Let Home-Manager manage itself
  ########################################
  programs.home-manager.enable = true;
}