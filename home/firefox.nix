{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.pywalfox-native ];
  };

  wayland.windowManager.hyprland.extraConfig = ''
    hl.bind("SUPER + F", hl.dsp.exec_cmd("firefox"))
  '';
}
