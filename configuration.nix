{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ---- Nix ----
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # ---- Boot: GRUB (UEFI) with Windows detection ----
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
    configurationLimit = 10;
  };

  # ---- Networking ----
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # ---- PASTE YOUR OLD time.timeZone / i18n / console keymap LINES HERE ----
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # ---- User ----
  users.users.Vi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
  };

  # ---- Hyprland + auto login ----
  programs.hyprland.enable = true;
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    autoLogin = {
      enable = true;
      user = "Vi";
    };
    defaultSession = "hyprland";
  };

  # ---- Audio ----
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # ---- Fonts ----
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
  ];

  # ---- Apps ----


  # Lets root's git trust your repo (needed for sudo nixos-rebuild with flakes)
  programs.git = {
    enable = true;
    config.safe.directory = "/home/Vi/nixos-config";
  };

  environment.systemPackages = with pkgs; [
    nano
    curl

    # The one command: rebuild  (or: rebuild update)
    (writeShellApplication {
      name = "rebuild";
      runtimeInputs = [ git ];
      text = ''
        cd /home/Vi/nixos-config || exit 1

        if [ "''${1:-}" = "update" ]; then
          nix flake update
        fi

        git add -A
        sudo nixos-rebuild switch --flake .#nixos
        git add -A
        git commit -m "rebuild: $(date '+%Y-%m-%d %H:%M')" || echo "Nothing new to commit"
        git push -u origin main
      '';
    })
  ];

  system.stateVersion = "26.05";
}
