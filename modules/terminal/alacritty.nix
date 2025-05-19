{ lib, pkgs, nixGL, helpers, ... }:

let
  nixBin = "${nixGL.packages.${pkgs.system}.nixGLIntel}/bin/nixGLIntel";
  # ── Alacritty wrapper (runs through nixGLIntel) ────────────────────────────
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    ${nixBin} ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  alacrittySvg = helpers.getAlacrittySvg pkgs.alacritty;
in
{
  programs.alacritty = {
    enable = true;
    package = alacrittyWrapped;

    settings = {
      env = {
        TERM = "xterm-256color";
      };

      window = {
        opacity = 0.9;
        decorations = "full";
        dynamic_title = true;
        dynamic_padding = true;
        startup_mode = "Maximized";
      };

      font = {
        size = 14;
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
      };

      colors = {
        primary = {
          background = "0x0F1419";
          foreground = "0xE6E1CF";
        };
        normal = {
          black = "0x0F1419";
          red = "0xF07178";
          green = "0xAAD94C";
          yellow = "0xFFB454";
          blue = "0x59C2FF";
          magenta = "0xD2A6FF";
          cyan = "0x95E6CB";
          white = "0xE6E1CF";
        };
        bright = {
          black = "0x3E4B59";
          red = "0xF07178";
          green = "0xAAD94C";
          yellow = "0xFFB454";
          blue = "0x59C2FF";
          magenta = "0xD2A6FF";
          cyan = "0x95E6CB";
          white = "0xF2F2F2";
        };
      };

      terminal = {
        shell = {
          program = "${pkgs.zsh}/bin/zsh";
        };
      };

      keyboard = {
        bindings = [
          {
            key = "V";
            mods = "Control|Shift";
            action = "Paste";
          }
          {
            key = "C";
            mods = "Control|Shift";
            action = "Copy";
          }
          {
            key = "Key0";
            mods = "Control";
            action = "ResetFontSize";
          }
          {
            key = "Equals";
            mods = "Control";
            action = "IncreaseFontSize";
          }
          {
            key = "Minus";
            mods = "Control";
            action = "DecreaseFontSize";
          }
        ];
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      selection = {
        save_to_clipboard = true;
      };
    };
  };

  # Add desktop-file-utils to home.packages
  home.packages = with pkgs; [
    desktop-file-utils
  ];

  # Ensure the config directory exists and write the config file
  home.activation = {
    installAlacrittyConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -e
      mkdir -p ~/.config/alacritty
      rm -f ~/.config/alacritty/alacritty.yml
      cat > ~/.config/alacritty/alacritty.yml << EOF
env:
  TERM: xterm-256color

window:
  opacity: 0.9
  decorations: full
  dynamic_title: true
  dynamic_padding: true
  startup_mode: Maximized

font:
  size: 14
  normal:
    family: JetBrainsMono Nerd Font
    style: Regular
  bold:
    family: JetBrainsMono Nerd Font
    style: Bold
  italic:
    family: JetBrainsMono Nerd Font
    style: Italic

colors:
  primary:
    background: '0x0F1419'
    foreground: '0xE6E1CF'
  normal:
    black: '0x0F1419'
    red: '0xF07178'
    green: '0xAAD94C'
    yellow: '0xFFB454'
    blue: '0x59C2FF'
    magenta: '0xD2A6FF'
    cyan: '0x95E6CB'
    white: '0xE6E1CF'
  bright:
    black: '0x3E4B59'
    red: '0xF07178'
    green: '0xAAD94C'
    yellow: '0xFFB454'
    blue: '0x59C2FF'
    magenta: '0xD2A6FF'
    cyan: '0x95E6CB'
    white: '0xF2F2F2'

terminal:
  shell:
    program: ${pkgs.zsh}/bin/zsh

keyboard:
  bindings:
    - key: V
      mods: Control|Shift
      action: Paste
    - key: C
      mods: Control|Shift
      action: Copy
    - key: Key0
      mods: Control
      action: ResetFontSize
    - key: Equals
      mods: Control
      action: IncreaseFontSize
    - key: Minus
      mods: Control
      action: DecreaseFontSize

scrolling:
  history: 10000
  multiplier: 3

selection:
  save_to_clipboard: true
EOF
    '';

    installAlacrittyDesktop = lib.hm.dag.entryAfter ["installAlacrittyConfig"] ''
      set -e
      mkdir -p ~/.local/share/applications
      rm -f ~/.local/share/applications/alacritty.desktop
      cat > ~/.local/share/applications/alacritty.desktop << EOF
[Desktop Entry]
Name=Alacritty
Exec=${alacrittyWrapped}/bin/alacritty
Icon=${alacrittySvg}
Type=Application
Categories=TerminalEmulator;
Terminal=false
EOF
      ${pkgs.desktop-file-utils}/bin/update-desktop-database ~/.local/share/applications
    '';

    installAlacrittyIcon = lib.hm.dag.entryAfter ["installAlacrittyDesktop"] ''
      set -e
      mkdir -p ~/.local/share/icons/hicolor/scalable/apps
      rm -f ~/.local/share/icons/hicolor/scalable/apps/alacritty.svg
      cp ${alacrittySvg} ~/.local/share/icons/hicolor/scalable/apps/alacritty.svg
      ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor
    '';
  };
} 