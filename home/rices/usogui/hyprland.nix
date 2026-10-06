{ config, ... }:

let
  walDir = "${config.home.homeDirectory}/.cache/wal";
in
{
  wayland.windowManager.hyprland = {
    settings = {
      exec-once = [ "waybar" ];

      general = {
        gaps_in = 4;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgb(ffffff)";
        "col.inactive_border" = "rgba(ffffff22)";
      };

      decoration = {
        rounding = 4;
        active_opacity = 1.0;
        inactive_opacity = 0.94;
        blur = {
          enabled = true;
          size = 5;
          passes = 2;
        };
        shadow = {
          enabled = true;
          range = 16;
          render_power = 3;
          color = "rgba(00000099)";
        };
      };

      animations = {
        enabled = true;
        bezier = [ "flick, 0.2, 1.2, 0.3, 1" ];
        animation = [
          "windows, 1, 4, flick, popin 80%"
          "fade, 1, 4, flick"
          "workspaces, 1, 5, flick, slide"
        ];
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };
    };

    # Wallpaper-derived border colors override the defaults above
    extraConfig = "source = ${walDir}/colors-hypr.conf";
  };
}
