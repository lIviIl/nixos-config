{ config, pkgs, ... }:

let
  # Absolute path: the idle daemon doesn't have your login PATH
  lockScreen = "${config.home.path}/bin/lock-screen";
in
{
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
  ];

  # Kept as the emergency fallback
  programs.hyprlock.enable = true;

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${lockScreen}";
        before_sleep_cmd = "loginctl lock-session";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  wayland.windowManager.hyprland.extraConfig = ''
    hl.bind("SUPER + L", hl.dsp.exec_cmd("lock-screen"))
    hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
    hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
  '';
}
