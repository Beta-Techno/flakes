{ lib, pkgs, ... }:
{
  # Add terminfo to system packages (simpler approach)
  environment.systemPackages = with pkgs; [
    # Create a simple terminfo entry for xterm-ghostty
    (runCommand "ghostty-terminfo"
      { nativeBuildInputs = [ ncurses ]; }
      ''
        mkdir -p $out/share/terminfo
        cat > ghostty.ti <<'EOF'
xterm-ghostty|Ghostty terminal emulator (alias of xterm-256color),
  use=xterm-256color,
EOF
        tic -x -o $out/share/terminfo ghostty.ti
      '')
  ];

  # (Optional but nice) Give tmux good defaults everywhere.
  programs.tmux = {
    enable = lib.mkDefault true;
    terminal = lib.mkDefault "tmux-256color";  # $TERM inside tmux
    extraConfig = ''
      # tmux ≥ 3.2: mark Ghostty as truecolor
      set -as terminal-features "xterm-ghostty:RGB"
      # Older tmux fallback:
      set -as terminal-overrides ",xterm-ghostty:Tc"
    '';
  };
}
