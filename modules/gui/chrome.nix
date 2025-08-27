{ config, pkgs, lib, helpers, ... }:

lib.mkIf (pkgs.stdenv.isx86_64 || pkgs.stdenv.isDarwin) {
  # ── Chrome package (wrapped + base) ────────────────────────────
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "google-chrome" ''
      exec env CHROME_DEVEL_SANDBOX=/usr/local/bin/chrome-sandbox \
           ${pkgs.google-chrome}/bin/google-chrome-stable "$@"
    '')
    (lib.lowPrio google-chrome)
  ];

  # ── Create desktop entry ────────────────────────────────────────
  home.activation.createChromeDesktopEntry = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.local/share/applications"
    $DRY_RUN_CMD cat > "$HOME/.local/share/applications/google-chrome.desktop" << EOF
[Desktop Entry]
Name=Google Chrome
Exec=google-chrome %U
Icon=google-chrome
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF
  '';

  # ── Create systemd tmpfiles rule for Chrome sandbox ────────────
  home.activation.createChromeSandboxRule = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/systemd/tmpfiles.d"
    $DRY_RUN_CMD cat > "$HOME/.config/systemd/tmpfiles.d/google-chrome-sandbox.conf" << EOF
# Type Path        Mode UID  GID  Age Argument
C     /usr/local/bin/chrome-sandbox 4755 root root - ${pkgs.google-chrome}/share/google/chrome/chrome-sandbox
EOF
  '';
} 