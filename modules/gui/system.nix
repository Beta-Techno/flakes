{ config, pkgs, lib, helpers, ... }:

{
  imports = [ 
    ./vscode.nix 
    ./postman.nix 
    ./jetbrains 
    ./dock.nix 
    ./fonts.nix 
    ./chrome.nix 
    # Note: theme.nix is NOT imported here - it's Home-Manager only
  ];
}
