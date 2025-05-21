{ pkgs, lib }:

let
  # ── Nix binary path ────────────────────────────────────────────
  nixBin = "${pkgs.nix}/bin/nix";

  # ── Helper binary *inside* the Google-Chrome derivation ─────────
  chromeSandboxInStore = "${pkgs.google-chrome}/libexec/chrome-sandbox";

  # ── Detect at runtime whether the set-uid helper is available ───
  sandboxFlag = ''
    if [ -x /usr/local/bin/chrome-sandbox ] && [ -u /usr/local/bin/chrome-sandbox ]; then
      echo "--sandbox-executable=/usr/local/bin/chrome-sandbox"
    else
      echo "--disable-setuid-sandbox"
    fi
  '';

  # ── Generic Chromium / Electron wrapper ─────────────────────────
  mkChromiumWrapper = { pkg, exe }:
    pkgs.writeShellScriptBin exe ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      extra=$(${sandboxFlag})
      exec ${pkg}/bin/${exe} "$extra" "$@"
    '';

  # ── Common Electron wrapper (keeps namespace sandbox) ──────────────────────
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --disable-setuid-sandbox "$@"
    '';

  # ── Chrome wrapper (uses installed SUID helper) ────────────────
  chromeWrapped = pkgs.writeShellScriptBin "google-chrome" ''
    exec ${pkgs.google-chrome}/bin/google-chrome-stable \
         --sandbox-executable=/usr/local/bin/chrome-sandbox "$@"
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
    mkChromiumWrapper
    wrapElectron
    chromeWrapped
    getAlacrittySvg
    createDesktopEntry
    installTerminfo;
} 