{ config, pkgs, lib, username, doomConfig, nix-doom, ... }:

{
  # Import the unstraightened Home Manager module
  imports = [ nix-doom.homeModule ];

  # Use the proper NixOS Doom Emacs module
  programs.doom-emacs = {
    enable = true;
    doomDir = doomConfig;  # Points to ./home/editors/doom
    doomLocalDir = "~/.local/share/nix-doom";  # Writable runtime dirs
    emacs = pkgs.emacs30-pgtk;
    extraPackages = epkgs: [
      epkgs.treesit-grammars.with-all-grammars
      epkgs.vterm
    ];
    # experimentalFetchTree = true;  # Enable if you hit "Cannot find Git revision" on newer Nix
    provideEmacs = true;  # Set false if you also want a separate vanilla Emacs
  };

  # Optional: Run Emacs as a user-level daemon
  services.emacs.enable = true;

  # Dependencies (some might be handled by the module, but keeping for safety)
  home.packages = with pkgs; [
    ripgrep
    fd
    imagemagick
    sqlite
    zstd
  ];
} 