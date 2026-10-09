{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "lock-screen" ''
      exec ${pkgs.hyprlock}/bin/hyprlock
    '')
  ];
}
