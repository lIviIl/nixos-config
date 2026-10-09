{ pkgs, ... }:

{
  home.packages = [
    # The Quickshell lock screen, falling back to hyprlock if the shell isn't running
    (pkgs.writeShellScriptBin "lock-screen" ''
      ${pkgs.quickshell}/bin/quickshell -c lelouch ipc call lock lock || exec ${pkgs.hyprlock}/bin/hyprlock
    '')
  ];
}
