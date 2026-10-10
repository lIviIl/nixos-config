{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  hardware.bluetooth.enable = true;

  environment.systemPackages = [ pkgs.brightnessctl ];
}
