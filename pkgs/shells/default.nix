{ pkgs, ... }:

let
  rustShell = import ./rust.nix { inherit pkgs; };
  pythonShell = import ./python.nix { inherit pkgs; };
  goShell = import ./go.nix { inherit pkgs; };
  nodejsShell = import ./nodejs.nix { inherit pkgs; };
in
pkgs.mkShell {
  name = "dev-shell";
  buildInputs = rustShell.buildInputs
    ++ pythonShell.buildInputs
    ++ goShell.buildInputs
    ++ nodejsShell.buildInputs;

  shellHook = ''
    echo "Development shell loaded"
    echo "Available languages:"
    echo "  - Rust"
    echo "  - Python"
    echo "  - Go"
    echo "  - Node.js"
  '';
} 