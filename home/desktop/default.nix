{ ... }:

{
  imports = [
    ./hyprland.nix
    ./wallpaper.nix
    ./lock-idle.nix
    ./capture.nix
  ];

  services.network-manager-applet.enable = true;
}
