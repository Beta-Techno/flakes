{ lib, platform, ... }:

let
  inherit (lib) mkOption types mkIf;
in
{
  ## Expose the pre-computed platform record as read-only
  options.platform = mkOption {
    type        = types.attrs;
    default     = platform;
    readOnly    = true;
    description = "Platform detection and capabilities passed via specialArgs";
  };

  ## Example: Darwin-only config (safe – evaluated after the graph exists)
  config = mkIf platform.isDarwin {
    assertions = [{
      assertion = platform.isDarwin;
      message   = "Darwin-specific profile imported on a non-Darwin host";
    }];
  };
} 