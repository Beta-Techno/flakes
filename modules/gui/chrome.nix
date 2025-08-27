{ config, pkgs, lib, helpers, ... }:

let
  # ── Chrome wrapper (uses installed SUID helper) ────────────────
  chromeWrapped = if pkgs.stdenv.isx86_64 || pkgs.stdenv.isDarwin then
    pkgs.writeShellScriptBin "google-chrome" ''
      exec env CHROME_DEVEL_SANDBOX=/usr/local/bin/chrome-sandbox \
           ${pkgs.google-chrome}/bin/google-chrome-stable "$@"
    ''
  else
    null;
in {
  # ── Chrome package (wrapped + base) ────────────────────────────
  home.packages = with pkgs; 
    lib.optionals (pkgs.stdenv.isx86_64 || pkgs.stdenv.isDarwin) [
      chromeWrapped
      (lib.lowPrio google-chrome)
    ];

  # ── Create desktop entry ────────────────────────────────────────
  home.activation.createChromeDesktopEntry = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ "$(uname -m)" = "x86_64" ] || [ "$(uname)" = "Darwin" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.local/share/applications"
      $DRY_RUN_CMD cat > "$HOME/.local/share/applications/google-chrome.desktop" << EOF
[Desktop Entry]
Name=Google Chrome
Exec=${if chromeWrapped != null then "${chromeWrapped}/bin/google-chrome" else "google-chrome"} %U
Icon=google-chrome
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF
    fi
  '';

  # ── Create systemd tmpfiles rule for Chrome sandbox ────────────
  home.activation.createChromeSandboxRule = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ "$(uname -m)" = "x86_64" ] || [ "$(uname)" = "Darwin" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/systemd/tmpfiles.d"
      $DRY_RUN_CMD cat > "$HOME/.config/systemd/tmpfiles.d/google-chrome-sandbox.conf" << EOF
# Type Path        Mode UID  GID  Age Argument
C     /usr/local/bin/chrome-sandbox 4755 root root - ${pkgs.google-chrome}/share/google/chrome/chrome-sandbox
EOF
    fi
  '';
} 