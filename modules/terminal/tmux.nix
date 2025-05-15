{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    historyLimit = 10000;
    shell = "${pkgs.zsh}/bin/zsh";
    shortcut = "Space";
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.resurrect
      tmuxPlugins.continuum
      tmuxPlugins.sensible
      tmuxPlugins.yank
      tmuxPlugins.vim-tmux-navigator
    ];

    extraConfig = ''
      # Improve color support
      set -ga terminal-overrides ",xterm-256color:Tc"

      # Set the pane border style
      set -g pane-border-style fg=colour238,bg=colour16  # Dark grey/blue
      set -g pane-active-border-style fg=colour75,bg=colour16  # Bright blue
      set -g pane-border-status top
      set -g pane-border-lines single

      # Enable mouse support
      set -g mouse on

      # Start windows and panes at 1, not 0
      set -g base-index 1
      setw -g pane-base-index 1

      # Automatically set window title
      setw -g automatic-rename on
      set -g set-titles on
      set -g set-titles-string "#T"

      # Renumber windows when one is closed
      set -g renumber-windows on

      # Enable focus events
      set -g focus-events on

      # Enable resurrect and continuum
      set -g @continuum-restore 'on'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-nvim 'session'

      # Status bar customization
      set -g status-style bg=default
      set -g status-left "#[fg=green]#H #[fg=black]• #[fg=green,bright]#(uname -r | cut -c 1-6)#[default]"
      set -g status-left-length 50
      set -g status-right "#[fg=black]• #[fg=green]#(cut -d ' ' -f 1-3 /proc/loadavg)#[default]"
      set -g status-right-length 50
      set -g status-interval 5
    '';
  };
} 