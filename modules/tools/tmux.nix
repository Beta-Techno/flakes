{ config, pkgs, lib, ... }:

{
  # ── Tmux package ───────────────────────────────────────────────
  home.packages = with pkgs; [
    tmux
  ];

  # ── Tmux configuration ─────────────────────────────────────────
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
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
      # Improve color support (Ghostty + fallback)
      set -as terminal-features "xterm-ghostty:RGB"
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

      # Pass through Ctrl+L to clear screen
      bind-key -n C-l send-keys C-l

      # ── Additional key bindings (improvements) ──────────────────
      # Split windows
      bind | split-window -h
      bind - split-window -v
      bind _ split-window -v

      # Vim style pane selection
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Use Alt-arrow keys without prefix key to switch panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Shift arrow to switch windows
      bind -n S-Left previous-window
      bind -n S-Right next-window

      # Set easier window split keys
      bind-key v split-window -h -c "#{pane_current_path}"
      bind-key s split-window -v -c "#{pane_current_path}"

      # Easy config reload
      bind-key r source-file ~/.tmux.conf \; display-message "Config reloaded!"
    '';
  };
} 