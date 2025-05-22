{ pkgs, lib }:

let
  # ── Nix binary path ────────────────────────────────────────────
  nixBin = "${pkgs.nix}/bin/nix";

  # ── Common Electron wrapper (keeps namespace sandbox) ───────────
  wrapElectron = pkg: exe:
    pkgs.writeShellScriptBin exe ''
      exec ${pkg}/bin/${exe} --no-sandbox "$@"
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
    getAlacrittySvg
    createDesktopEntry
    installTerminfo;
} 