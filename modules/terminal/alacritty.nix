{ lib, pkgs, nixGL, ... }:

let
  nixBin = "${nixGL.packages.${pkgs.system}.nixGLIntel}/bin/nixGLIntel";
  # ── Alacritty wrapper (runs through nixGLIntel) ────────────────────────────
  alacrittyWrapped = pkgs.writeShellScriptBin "alacritty" ''
    ${nixBin} ${pkgs.alacritty}/bin/alacritty "$@"
  '';

  alacrittySvg = "${pkgs.alacritty}/share/applications/Alacritty.svg";
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

      shell = {
        program = "${pkgs.zsh}/bin/zsh";
      };

      key_bindings = [
        { key = "V"; mods = "Control|Shift"; action = "Paste"; }
        { key = "C"; mods = "Control|Shift"; action = "Copy"; }
        { key = "Key0"; mods = "Control"; action = "ResetFontSize"; }
        { key = "Equals"; mods = "Control"; action = "IncreaseFontSize"; }
        { key = "Minus"; mods = "Control"; action = "DecreaseFontSize"; }
      ];

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      selection = {
        save_to_clipboard = true;
      };
    };
  };

  # Desktop launcher and icon installation
  home.activation = {
    installAlacrittyDesktop = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.local/share/applications
      $DRY_RUN_CMD rm -f $VERBOSE_ARG ~/.local/share/applications/alacritty.desktop
      $DRY_RUN_CMD cat > $VERBOSE_ARG ~/.local/share/applications/alacritty.desktop << EOF
[Desktop Entry]
Name=Alacritty
Exec=${alacrittyWrapped}/bin/alacritty
Icon=${alacrittySvg}
Type=Application
Categories=TerminalEmulator;
Terminal=false
EOF
      $DRY_RUN_CMD update-desktop-database $VERBOSE_ARG ~/.local/share/applications
    '';

    installAlacrittyIcon = lib.hm.dag.entryAfter ["installAlacrittyDesktop"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.local/share/icons/hicolor/scalable/apps
      $DRY_RUN_CMD rm -f $VERBOSE_ARG ~/.local/share/icons/hicolor/scalable/apps/alacritty.svg
      $DRY_RUN_CMD cp $VERBOSE_ARG ${alacrittySvg} ~/.local/share/icons/hicolor/scalable/apps/alacritty.svg
      $DRY_RUN_CMD gtk-update-icon-cache $VERBOSE_ARG -f -t ~/.local/share/icons/hicolor
    '';
  };
} 