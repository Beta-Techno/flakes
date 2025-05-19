{ pkgs, lib }:

let
  inherit (lib) mapAttrs;
in
mapAttrs (name: value: value.override { inherit pkgs lib; }) {
  inherit (import ./. { inherit pkgs lib; })
    auth
    setup
    sync-repos
    doctor
    activate;
} 