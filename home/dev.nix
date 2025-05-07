{ pkgs, lib, ... }:

let
  # ── Helper: wrap an Electron app with --no-sandbox ──────────────
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
    '';

  # ── Helper: Alacritty via nixGL (GPU auto-detect) ───────────────
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    exec nix run --impure github:guibou/nixGL -c nixGL \
         ${pkgs.alacritty}/bin/alacritty "$@"
  '';
in
{
  targets.genericLinux.enable = true;

  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # ── Packages ────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # CLI
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # Electron (wrapped)
    (wrapElectron pkgs.vscode  "code")
    (wrapElectron pkgs.postman "postman")
    (lib.lowPrio pkgs.vscode) (lib.lowPrio pkgs.postman)

    # JetBrains IDEs
    jetbrains.datagrip
    jetbrains.rider

    # GUI apps
    emacs29-pgtk
    alacrittyWrapped
    (lib.lowPrio pkgs.alacritty)
    google-chrome
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # Shell, tmux, git, aliases … (unchanged from previous version)
  programs.zsh.enable            = true;
  programs.zsh.oh-my-zsh.enable  = true;
  programs.zsh.oh-my-zsh.theme   = "agnoster";

  programs.tmux.enable = true;
  programs.tmux.extraConfig = ''
    set -g mouse on
    set -g history-limit 100000
  '';

  programs.git.enable   = true;
  programs.git.userName = "Rob";
  programs.git.userEmail = "rob@example.com";

  home.shellAliases = { k = "kubectl"; dcu = "docker compose up -d"; dcd = "docker compose down"; };

  fonts.fontconfig.enable = true;

  # Ghostty terminfo
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.terminfo"
    tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
  '';

  # Cloudflared tunnel
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service.ExecStart =
      "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
    Service.Restart  = "on-failure";
    Install.WantedBy = [ "default.target" ];
  };

  programs.home-manager.enable = true;
}