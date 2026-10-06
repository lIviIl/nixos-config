{ config, ... }:

let
  walDir = "${config.home.homeDirectory}/.cache/wal";
in
{
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 38;
      margin-top = 8;
      margin-left = 12;
      margin-right = 12;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = "A";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
          "10" = "10";
          "11" = "J";
          "12" = "Q";
          "13" = "K";
          default = "·";
        };
        persistent-workspaces = { "*" = 5; };
      };

      clock = {
        format = "{:%H:%M}";
        tooltip-format = "{:%A, %d %B %Y}";
      };

      pulseaudio = {
        format = "VOL {volume}%";
        format-muted = "MUTED";
      };

      network = {
        format-wifi = "{essid}";
        format-ethernet = "wired";
        format-disconnected = "offline";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "BAT {capacity}%";
        format-charging = "CHG {capacity}%";
        format-plugged = "AC {capacity}%";
      };

      tray.spacing = 10;
    };

    style = ''
      @import "${walDir}/colors-waybar.css";

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
        font-weight: bold;
        border: none;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: @foreground;
      }

      #workspaces, #clock, #pulseaudio, #network, #battery, #tray {
        background: alpha(@background, 0.88);
        border: 2px solid @foreground;
        border-radius: 4px;
        padding: 0 14px;
        margin: 0 4px;
      }

      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        padding: 0 10px;
        margin: 3px 2px;
        color: alpha(@foreground, 0.5);
        background: transparent;
        border-radius: 3px;
        box-shadow: none;
        text-shadow: none;
      }

      #workspaces button:hover {
        color: @foreground;
        background: alpha(@color4, 0.3);
      }

      #workspaces button.active {
        color: @background;
        background: @color4;
      }

      #workspaces button.urgent {
        color: #ff4d5e;
      }

      #clock {
        letter-spacing: 3px;
      }

      #pulseaudio.muted {
        color: alpha(@foreground, 0.5);
      }

      #battery.warning {
        color: #ffd479;
      }

      #battery.critical {
        color: #ff4d5e;
      }
    '';
  };
}
