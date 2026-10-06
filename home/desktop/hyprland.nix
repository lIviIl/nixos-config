{ ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    # Use the Hyprland from the NixOS module so versions can't mismatch
    package = null;
    portalPackage = null;

    settings = {
      "$mod" = "SUPER";
      monitor = ",preferred,auto,1";

      exec-once = [ "wallpaper restore" ];

      general.layout = "dwindle";

      dwindle.preserve_split = true;

      # Hyprland 0.56 started honoring "launch maximized" requests from apps,
      # which makes new windows cover the screen instead of tiling. Ignore them.
      windowrule = [
        "match:class .*, suppress_event maximize"
      ];

      input.touchpad = {
        natural_scroll = true;
        tap-to-click = true;
      };

      bind = [
        "$mod, W, exec, wallpaper"
        "$mod, Q, killactive,"
        "$mod, V, togglefloating,"
        "$mod, M, fullscreen,"
        "$mod SHIFT, E, exit,"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod CTRL, right, workspace, +1"
        "$mod CTRL, left, workspace, e-1"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ] ++ (builtins.concatLists (builtins.genList (i:
        let
          n = i + 1;
          ws = toString n;
          key = if n == 10 then "0" else ws;
        in [
          "$mod, ${key}, workspace, ${ws}"
          "$mod SHIFT, ${key}, movetoworkspace, ${ws}"
        ]) 10));

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ];
    };
  };
}
