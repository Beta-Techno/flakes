{ config, pkgs, lib, helpers, ... }:

let
  # Create a wrapper for Chrome that uses the SUID sandbox
  chromeWrapped = pkgs.writeShellScriptBin "google-chrome" ''
    if [ -x /usr/local/bin/chrome-sandbox ]; then
      exec env CHROME_DEVEL_SANDBOX=/usr/local/bin/chrome-sandbox \
           ${pkgs.google-chrome}/bin/google-chrome-stable \
           --sandbox-executable=/usr/local/bin/chrome-sandbox "$@"
    else
      exec ${pkgs.google-chrome}/bin/google-chrome-stable --disable-setuid-sandbox "$@"
    fi
  '';
in {
  # ── Chrome package (wrapped + base) ────────────────────────────
  home.packages = with pkgs; [
    chromeWrapped        # The wrapper (binary "google-chrome")
    (lib.lowPrio google-chrome)  # Base package for icons/resources
  ];

  # ── Create desktop entry ────────────────────────────────────────
  home.activation.createChromeDesktopEntry = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.local/share/applications"
    $DRY_RUN_CMD cat > "$HOME/.local/share/applications/google-chrome.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Chrome
Comment=Access the Internet
Exec=${chromeWrapped}/bin/google-chrome %U
Icon=${pkgs.google-chrome}/share/icons/hicolor/256x256/apps/google-chrome.png
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-extension-htm;application/x-extension-html;application/x-extension-shtml;application/xhtml+xml;application/x-extension-xhtml;application/x-extension-xht;
StartupNotify=true
Actions=new-window;new-private-window;
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