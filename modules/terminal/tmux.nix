{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    historyLimit = 10000;
    shell = "${pkgs.zsh}/bin/zsh";
    shortcut = "C-b";
    baseIndex = 0;
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

      # Start windows and panes at 0
      set -g base-index 0
      setw -g pane-base-index 0

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
    '';
  };
} 