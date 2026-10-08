{ config, pkgs, ... }:

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

  # The service doesn't inherit your login PATH, so give it the user profile.
  # KillMode=process keeps launched apps alive if the shell restarts.
  systemd.user.services.quickshell.Service = {
    Environment = [ "PATH=/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/run/wrappers/bin" ];
    KillMode = "process";
  };

  # notify-send, for testing notifications
  home.packages = [ pkgs.libnotify ];

  # The shell's overlays are opened over IPC
  wayland.windowManager.hyprland.extraConfig = ''
    hl.bind("SUPER + D", hl.dsp.exec_cmd("qs -c lelouch ipc call launcher toggle"))
    hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("qs -c lelouch ipc call wallpaper toggle"))
  '';
}
