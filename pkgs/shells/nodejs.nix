{ pkgs, ... }:

{
  buildInputs = with pkgs; [
    # Node.js toolchain (match toolsets)
    nodejs_22
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