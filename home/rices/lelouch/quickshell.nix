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

  systemd.user.services.quickshell = {
    # Restart the shell whenever any of its files change, so a rebuild is always enough
    Unit."X-Restart-Triggers" = [ "${./shell}" ];

    Service = {
      # The service doesn't inherit your login PATH, so give it the user profile.
      # KillMode=process keeps launched apps alive if the shell restarts.
      Environment = [ "PATH=/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/run/wrappers/bin" ];
      KillMode = "process";
    };
  };

  home.packages = [
    # notify-send, for testing notifications
    pkgs.libnotify

    # Gathers the command center's system statistics in one pass
    (pkgs.writeShellScriptBin "lelouch-sysinfo" ''
      export PATH=${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.gnused pkgs.procps pkgs.iproute2 pkgs.util-linux ]}:$PATH
      ${builtins.readFile ./sysinfo.sh}
    '')
  ];

  # The shell's overlays are opened over IPC
  wayland.windowManager.hyprland.extraConfig = ''
    hl.bind("SUPER + D", hl.dsp.exec_cmd("qs -c lelouch ipc call launcher toggle"))
    hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("qs -c lelouch ipc call wallpaper toggle"))
    hl.bind("SUPER + C", hl.dsp.exec_cmd("qs -c lelouch ipc call center toggle"))
  '';
}
