{ lib, pkgs, ... }:
let
  # Minimal, safe alias: xterm-ghostty → xterm-256color
  # (tmux truecolor is enabled separately below; this prevents the "missing or unsuitable terminal" error.)
  ghosttyTerminfo = pkgs.runCommand "ghostty-terminfo"
    { nativeBuildInputs = [ pkgs.ncurses ]; }
    ''
      mkdir -p $out/share/terminfo
      cat > ghostty.ti <<'EOF'
xterm-ghostty|Ghostty terminal emulator (alias of xterm-256color),
  use=xterm-256color,
EOF
      tic -x -o $out/share/terminfo ghostty.ti
    '';
in
{
  # Make the entry visible to ncurses system-wide (sudo, services, every user)
  environment.etc."terminfo/x/xterm-ghostty".source =
    "${ghosttyTerminfo}/share/terminfo/x/xterm-ghostty";

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
