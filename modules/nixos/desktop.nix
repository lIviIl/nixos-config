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
}
