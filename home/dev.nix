{ pkgs, ... }:

/* =====================================================================
   Home‑Manager configuration for user "rob" — STABLE 24.05 ONLY
   ---------------------------------------------------------------------
   • All GUI apps, CLI tools, fonts, themes, and dot‑files live here.
   • This file is imported by flake.nix → homeConfigurations.rob.
   • After editing, run:  home-manager switch  (or the bootstrap helper).
   ===================================================================== */

{
  # ------------------------------------------------------------------
  # Core metadata — adjust if your username or $HOME differs
  # ------------------------------------------------------------------
  home.username      = "rob";
  home.homeDirectory = "/home/rob";

  # Keep in sync with your current Nixpkgs release when upgrading.
  home.stateVersion  = "24.05";

  # ------------------------------------------------------------------
  # Packages (GUI + CLI) installed into ~/.local/state/nix/profile/bin
  # ------------------------------------------------------------------
  home.packages = with pkgs; [

    /* ===== GUI applications ===== */
    # Editors / IDEs ---------------------------------------------------
    vscode                      # Visual Studio Code (unfree)
    emacs29-pgtk                # Native‑comp Emacs; adjust build if needed
    neovim                      # For quick edits + LazyVim config
    
    # JetBrains IDEs (bundled JBR)
    jetbrains.datagrip
    jetbrains.rider

    # Terminals --------------------------------------------------------
    ghostty                     # GPU‑accelerated terminal (early release)
    alacritty

    # Browsers & helpers ---------------------------------------------
    google-chrome               # Unfree; enable allowUnfree in flake
    postman                     # API client

    # Docker client (daemon runs via distro service or rootless setup)
    docker-client

    /* ===== CLI toolchain ===== */
    git                         # Version control
    inetutils                   # Provides `ifconfig`
    tmux                        # Terminal multiplexer
    ripgrep fd bat fzf          # Modern command‑line swiss‑army knives
    jq                          # JSON query
    gh                          # GitHub CLI
    htop                        # Process viewer
  ];

  # ------------------------------------------------------------------
  # Program‑specific modules (dot‑files as code)
  # ------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    oh-my-zsh.enable = true;
    oh-my-zsh.theme  = "agnoster";
  };

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g mouse on
      set -g history-limit 100000
    '';
  };

  programs.git = {
    enable = true;
    userName  = "Nick D'Amico";
    userEmail = "nick@example.com";  # ← update
    extraConfig = {
      pull.rebase = true;
    };
  };

  # ------------------------------------------------------------------
  # User‑mode systemd services (example: cloudflared tunnel)
  # ------------------------------------------------------------------
  systemd.user.services.cloudflared = {
    Unit = {
      Description = "Cloudflare Tunnel (user scope)";
      After = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # ------------------------------------------------------------------
  # Aliases & shell customisations
  # ------------------------------------------------------------------
  home.shellAliases = {
    k = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };

  # ------------------------------------------------------------------
  # Fonts, themes, etc. (examples; optional)
  # ------------------------------------------------------------------
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; (self: self.home.packages) ++ [
    nerdfonts
  ];
}