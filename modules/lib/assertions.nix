{ lib, platform, pkgs, ... }:

let
  inherit (lib) mkOption types mkIf;
  system = pkgs.stdenv.system;
in
{
  ## Expose the pre-computed platform record as read-only
  options.platform = mkOption {
    type        = types.attrs;
    default     = platform;
    readOnly    = true;
    description = "Platform detection and capabilities passed via specialArgs";
  };

  ## Platform-specific assertions
  config = {
    assertions = [
      {
        assertion = !platform.isDarwin || (platform.isDarwin && (system == "aarch64-darwin" || system == "x86_64-darwin"));
        message = "The module targets.darwin.defaults does not support your platform. It only supports:\n- aarch64-darwin\n- x86_64-darwin";
      }
      {
        assertion = !platform.isLinux || (platform.isLinux && (system == "x86_64-linux" || system == "aarch64-linux"));
        message = "The module targets.linux.defaults does not support your platform. It only supports:\n- x86_64-linux\n- aarch64-linux";
      }
    ];
  };
} 