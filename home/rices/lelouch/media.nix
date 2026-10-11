{ pkgs, ... }:

{
  home.packages = [
    pkgs.cava         # the visualizer's data source
    pkgs.pulseaudio   # pactl: Bluetooth audio profiles
  ];

  # cava configuration for the command center: raw numbers on stdout
  xdg.configFile."lelouch-cava/config".text = ''
    [general]
    bars = 32
    framerate = 30

    [input]
    method = pipewire
    source = auto

    [output]
    method = raw
    raw_target = /dev/stdout
    data_format = ascii
    ascii_max_range = 100
    bar_delimiter = 59
    frame_delimiter = 10

    [smoothing]
    noise_reduction = 60
  '';
}
