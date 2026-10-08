{ ... }:

{
  programs.firefox.enable = true;

  wayland.windowManager.hyprland.extraConfig = ''
    hl.bind("SUPER + F", hl.dsp.exec_cmd("firefox"))
  '';
}
