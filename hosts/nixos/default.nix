{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/apps.nix
    ../../modules/nixos/rebuild.nix
  ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # ---- PASTE YOUR OLD time.timeZone / i18n / console keymap LINES HERE ----
  time.timeZone = "Africa/Cairo";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.Vi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
  };

  system.stateVersion = "26.05";
}
