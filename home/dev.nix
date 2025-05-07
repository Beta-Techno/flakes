# =============================
#  home/dev.nix — packages & terminfo
# =============================
{ pkgs, lib, ... }:
{
  home.username      = "rob";
  home.homeDirectory = "/home/rob";
  home.stateVersion  = "24.05";

  # ------------ Packages (CLI + GUI) ----------
  home.packages = with pkgs; [
    # --- CLI tools ---
    tmux git ripgrep fd bat fzf jq htop inetutils
    neovim nodejs_20 docker-compose kubectl

    # --- GUI apps ---
    vscode                        # VS Code
    zed-editor                    # Zed
    emacs29-pgtk                  # GUI Emacs (pgtk build)
    ghostty                       # Terminal ­(GPU-rendered)
    alacritty                     # Terminal
    jetbrains.datagrip            # JetBrains DataGrip
    jetbrains.rider               # JetBrains Rider
    google-chrome                 # Chrome browser
    postman                       # API client
    docker-desktop                # Docker Desktop for Linux

    # NOTE: Cursor AI editor is not in nixpkgs yet.
    #       We can add it via an overlay/AppImage later.
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # ------------ Shell & tools  ----------------
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
    enable    = true;
    userName  = "Rob";
    userEmail = "rob@example.com";
  };

  home.shellAliases = {
    k   = "kubectl";
    dcu = "docker compose up -d";
    dcd = "docker compose down";
  };

  fonts.fontconfig.enable = true;

  # ------------ Ghostty terminfo --------------
  home.file."terminfo/ghostty.terminfo".source = ../terminfo/ghostty.terminfo;
  home.activation.installGhosttyTerminfo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.terminfo"
    tic -x -o "$HOME/.terminfo" ${../terminfo/ghostty.terminfo}
  '';

  # ------------ Services ----------------------
  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Tunnel (user scope)";
    Service = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run --cred-file %h/.cloudflared/tunnel.json";
      Restart   = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Let Home-Manager manage itself
  programs.home-manager.enable = true;
}