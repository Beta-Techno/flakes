{ pkgs, ... }:

{
  buildInputs = with pkgs; [
    # Rust toolchain
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy

    # Development tools
    cargo-edit
    cargo-outdated
    cargo-udeps
    cargo-watch
    cargo-expand
    cargo-audit
    cargo-deny
    cargo-msrv
    cargo-nextest
    cargo-tarpaulin
  ];
} 