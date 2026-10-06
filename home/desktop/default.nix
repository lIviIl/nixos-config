{ ... }:

{
  imports = [
    ./hyprland.nix
    ./wallpaper.nix
    ./lock-idle.nix
  ];

  services.network-manager-applet.enable = true;
}
