{ config, ... }:

let
  walDir = "${config.home.homeDirectory}/.cache/wal";
in
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      background_opacity = "0.9";
      window_padding_width = 14;
      confirm_os_window_close = 0;
      cursor_shape = "block";
    };
    extraConfig = "include ${walDir}/colors-kitty.conf";
  };

  wayland.windowManager.hyprland.settings.bind = [
    "$mod, Return, exec, kitty"
  ];
}
