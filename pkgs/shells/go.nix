{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Go toolchain
    go
    gopls
    gotools
    gopkgs  # Go packages
    godef  # Go definition
    golint  # Go linter
    gocode-gomod  # Go module support
    gore  # Go REPL
    goreleaser  # Release automation
    golangci-lint  # Linter
    delve  # Debugger

    # Doom dependencies
    gotools  # Go tools
    golangci-lint  # Go linter
  ];
} 