{ pkgs, ... }:

{
  buildInputs = with pkgs; [
    # Node.js toolchain
    nodejs_20
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm

    # Development tools
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.prettier
    nodePackages.eslint
    nodePackages.jsonlint
  ];
} 