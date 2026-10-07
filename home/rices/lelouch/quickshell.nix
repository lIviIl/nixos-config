{ ... }:

{
  programs.quickshell = {
    enable = true;
    activeConfig = "lelouch";
    configs.lelouch = ./shell;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };

  # The shell's overlays are opened over IPC
  wayland.windowManager.hyprland.extraConfig = ''
    hl.bind("SUPER + D", hl.dsp.exec_cmd("qs -c lelouch ipc call launcher toggle"))
    hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("qs -c lelouch ipc call wallpaper toggle"))
  '';
}
