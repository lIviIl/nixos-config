{ config, pkgs, ... }:

let
  walDir = "${config.home.homeDirectory}/.cache/wal";
in
{
  home.packages = [ pkgs.rofi ];

  wayland.windowManager.hyprland.settings.bind = [
    "$mod, D, exec, rofi -show drun"
  ];

  xdg.configFile."rofi/config.rasi".text = ''
    @import "${walDir}/colors-rofi.rasi"

    configuration {
      modi: "drun";
      show-icons: false;
      font: "JetBrainsMono Nerd Font Bold 13";
      display-drun: "嘘喰い";
      drun-display-format: "{name}";
    }

    window {
      width: 540px;
      background-color: @bg;
      border: 2px;
      border-color: @fg;
      border-radius: 4px;
    }

    mainbox {
      padding: 20px;
      spacing: 14px;
      background-color: transparent;
      children: [ inputbar, listview ];
    }

    inputbar {
      padding: 10px 6px;
      spacing: 12px;
      background-color: transparent;
      text-color: @fg;
      border: 0 0 2px 0;
      border-color: @accent;
      children: [ prompt, entry ];
    }

    prompt {
      text-color: @accent;
      background-color: transparent;
    }

    entry {
      text-color: @fg;
      background-color: transparent;
      placeholder: "place your bet";
      placeholder-color: @dim;
    }

    listview {
      lines: 6;
      spacing: 6px;
      scrollbar: false;
      fixed-height: false;
      border: 0;
      padding: 4px 0 0 0;
      background-color: transparent;
    }

    element {
      padding: 10px 12px;
      border-radius: 3px;
    }

    element normal.normal, element alternate.normal,
    element normal.active, element alternate.active,
    element normal.urgent, element alternate.urgent {
      background-color: transparent;
      text-color: @fg;
    }

    element selected.normal, element selected.active, element selected.urgent {
      background-color: @accent;
      text-color: @bg;
    }

    element-text {
      background-color: inherit;
      text-color: inherit;
    }
  '';
}
