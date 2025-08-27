{ lib, pkgs, ... }:

let
  inherit (lib) mkOption types mkIf;
  system = pkgs.stdenv.system;
in
{
  ## Platform-specific assertions
  config = {
    assertions = [
      {
        assertion = !pkgs.stdenv.isDarwin || (pkgs.stdenv.isDarwin && (system == "aarch64-darwin" || system == "x86_64-darwin"));
        message = "The module targets.darwin.defaults does not support your platform. It only supports:\n- aarch64-darwin\n- x86_64-darwin";
      }
      {
        assertion = !pkgs.stdenv.isLinux || (pkgs.stdenv.isLinux && (system == "x86_64-linux" || system == "aarch64-linux"));
        message = "The module targets.linux.defaults does not support your platform. It only supports:\n- x86_64-linux\n- aarch64-linux";
      }
    ];
  };
} 