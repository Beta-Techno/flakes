{ config, pkgs, lib, helpers, ... }:

{
  imports = [ 
    ./vscode.nix 
    ./postman.nix 
    ./jetbrains 
    ./fonts.nix 
    ./chrome.nix 
    # Note: theme.nix and dock.nix are NOT imported here - they're Home-Manager only
  ];
}
