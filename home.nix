{ pkgs, ... }:

{
  home.username = "Vi";
  home.homeDirectory = "/home/Vi";
  home.stateVersion = "26.05";

  programs.git = {
    enable = true;
    settings = {
      user.name = "lIviIl";
      user.email = "4aser.mo@gmail.com";
      init.defaultBranch = "main";
    };
  };

  programs.kitty.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    # Use the Hyprland from the NixOS module so versions can't mismatch
    package = null;
    portalPackage = null;

    settings = {
      "$mod" = "SUPER";
      monitor = ",preferred,auto,1";

      bind = [
        "$mod, Return, exec, kitty"
        "$mod, F, exec, firefox"
        "$mod, Q, killactive,"
        "$mod SHIFT, E, exit,"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
