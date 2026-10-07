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
}
