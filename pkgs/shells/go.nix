{ pkgs, ... }:

{
  buildInputs = with pkgs; [
    # Go toolchain
    go
    gopls  # Go LSP
    gotools  # Go tools
    go-outline  # Go outline
    gopkgs  # Go packages
    godef  # Go definition
    golint  # Go linter
    gocode  # Go code completion
    gocode-gomod  # Go module support
    gore  # Go REPL
    goreleaser  # Release automation
    golangci-lint  # Linter
    delve  # Debugger

    # Doom dependencies
    gopls  # Go LSP server
    gotools  # Go tools
    golangci-lint  # Go linter
  ];
} 