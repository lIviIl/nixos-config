{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.pywalfox-native ];
  };

  wayland.windowManager.hyprland.settings.bind = [
    "$mod, F, exec, firefox"
  ];
}
