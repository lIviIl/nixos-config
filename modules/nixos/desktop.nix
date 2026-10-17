{ ... }:

{
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

  security.pam.services.hyprlock = {};
  security.pam.services.lelouch-lock = {};

  # Electron apps (Vesktop) and Chromium-based apps use Wayland natively
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
