{ pkgs, lib }:

let
  # ── Nix binary path ────────────────────────────────────────────
  nixBin = "${pkgs.nix}/bin/nix";

  # ── Common Electron wrapper (keeps namespace sandbox) ──────────────────────
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --disable-setuid-sandbox "$@"
    '';

  # ── Chrome wrapper (uses installed SUID helper) ────────────────
  chromeWrapped = pkg:
    pkgs.writeShellScriptBin "google-chrome" ''
      exec ${pkg}/bin/google-chrome-stable \
           --sandbox-executable=/usr/local/bin/chrome-sandbox "$@"
    '';

  # ── Get Alacritty SVG icon path ────────────────────────────────
  getAlacrittySvg = pkg:
    "${pkg}/share/icons/hicolor/scalable/apps/Alacritty.svg";

  # ── Create desktop entry ────────────────────────────────────────
  createDesktopEntry = { fileName ? "google-chrome.desktop", name, exec, icon, type ? "Application", categories ? [], startupNotify ? true }:
    pkgs.writeTextFile {
      name = fileName;               # Use canonical filename (no spaces)
      text = ''
        [Desktop Entry]
        Name=${name}
        Exec=${exec} %U
        Icon=${icon}
        Type=${type}
        Categories=${lib.concatStringsSep ";" categories}
        StartupNotify=${if startupNotify then "true" else "false"}
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