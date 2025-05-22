{ pkgs, lib }:

let
  # ── Nix binary path ────────────────────────────────────────────
  nixBin = "${pkgs.nix}/bin/nix";

  # ── Helper binary *inside* the Google-Chrome derivation ─────────
  chromeSandboxInStore = "${pkgs.google-chrome}/libexec/chrome-sandbox";

  # ── Chrome wrapper (uses namespace sandbox by default) ──────────
  chromeWrapped = pkgs.writeShellScriptBin "google-chrome" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    if [ -x /usr/local/bin/chrome-sandbox ]; then
      # We really do have a properly installed SUID helper → use it
      exec env CHROME_DEVEL_SANDBOX=/usr/local/bin/chrome-sandbox "${pkgs.google-chrome}/bin/google-chrome-stable" --sandbox-executable=/usr/local/bin/chrome-sandbox "$@"
    else
      # unset CHROME_DEVEL_SANDBOX → guarantees no SUID attempt
      exec env -u CHROME_DEVEL_SANDBOX "${pkgs.google-chrome}/bin/google-chrome-stable" --disable-setuid-sandbox "$@"
    fi
  '';

  # ── Common Electron wrapper (keeps namespace sandbox) ───────────
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # Get the actual binary path from the package
      BIN="${pkg}/bin/${exe}"

      # If it's a shell script, read the actual binary path from it
      if [ -f "$BIN" ] && [ "$(head -n1 "$BIN" | cut -c1-2)" = "#!" ]; then
        # Extract the actual binary path from the wrapper
        # First try to find the binary in the package's share directory
        SHARE_BIN="${pkg}/share/$(basename "$exe")/$(basename "$exe")"
        if [ -f "$SHARE_BIN" ]; then
          BIN="$SHARE_BIN"
        else
          # If not found, try to extract from the wrapper
          ACTUAL_BIN=$(grep -m1 'exec' "$BIN" | sed -E 's/.*exec.*"([^"]+)".*/\1/')
          if [ -n "$ACTUAL_BIN" ]; then
            BIN="$ACTUAL_BIN"
          fi
        fi
      fi

      # Run the binary with our flags
      exec "$BIN" --disable-setuid-sandbox "$@"
    '';

  # ── Get Alacritty SVG icon path ────────────────────────────────
  getAlacrittySvg = pkg:
    "${pkg}/share/icons/hicolor/scalable/apps/Alacritty.svg";

  # ── Create desktop entry ────────────────────────────────────────
  createDesktopEntry = { fileName ? "google-chrome.desktop", name, exec, icon, type ? "Application", categories ? [], mimeTypes ? [], startupNotify ? true }:
    pkgs.writeTextFile {
      name = fileName;               # Use canonical filename (no spaces)
      text = ''
        [Desktop Entry]
        Version=1.0
        Type=${type}
        Name=${name}
        Comment=Access the Internet
        Exec=${exec} %U
        Icon=${icon}
        Categories=${lib.concatStringsSep ";" categories};
        MimeType=${lib.concatStringsSep ";" mimeTypes};
        StartupNotify=${if startupNotify then "true" else "false"}
        Actions=new-window;new-private-window;
      '';
    };

  # ── Install terminfo ────────────────────────────────────────────
  installTerminfo = { name, source }:
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.terminfo"
      tic -x -o "$HOME/.terminfo" ${source}
    '';

in {
  inherit
    nixBin
    wrapElectron
    chromeWrapped
    getAlacrittySvg
    createDesktopEntry
    installTerminfo;
} 