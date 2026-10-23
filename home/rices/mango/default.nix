{ inputs, lib, pkgs, ... }:

# The Mango rice. It is kept separate from the Lelouch rice (home/rices/lelouch): that one runs only under Hyprland,
# this one only under Mango. Read README.md in this folder before changing anything.
# It starts blank: a terminal, a launcher and a few keys, so there is something to work with.
let
  tag = lib.concatMap (i: let n = toString i; in [
    "SUPER,${n},view,${n},0"
    "SUPER+SHIFT,${n},tag,${n},0"
  ]) (lib.range 1 9);
in
{
  imports = [ inputs.mango.hmModules.mango ];

  home.packages = [ pkgs.fuzzel ];

  wayland.windowManager.mango = {
    enable = true;

    settings = {
      bind = [
        "SUPER,Return,spawn,kitty"
        "SUPER,d,spawn,fuzzel"
        "SUPER,q,killclient,"
        "SUPER,r,reload_config"
        "SUPER+SHIFT,e,spawn,switch-session hyprland"
        "SUPER,l,spawn,lock-screen"
        "SUPER,f,togglefullscreen,"
        "SUPER,v,togglefloating,"
        "SUPER,n,switch_layout"
        "SUPER,Tab,focusstack,next"
        "SUPER,Left,focusdir,left"
        "SUPER,Right,focusdir,right"
        "SUPER,Up,focusdir,up"
        "SUPER,Down,focusdir,down"

        # Back to Hyprland and the Lelouch rice (closes every window here)
        "SUPER+CTRL,h,spawn,switch-session hyprland"

        "NONE,XF86MonBrightnessUp,spawn,brightnessctl set +5%"
        "NONE,XF86MonBrightnessDown,spawn,brightnessctl set 5%-"
        "NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        "NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ] ++ tag;
    };

    # Runs when Mango starts (no shebang needed)
    autostart_sh = ''
      # Lock on arrival when this session was switched to from a lock screen. Keep this line.
      relock-if-flagged 3 &

      # First start only: a window that says how to find your way around, and back to Hyprland
      if [ ! -e "$HOME/.cache/lelouch/mango-hint-seen" ]; then
        mkdir -p "$HOME/.cache/lelouch"
        touch "$HOME/.cache/lelouch/mango-hint-seen"
        kitty --title "Mango" sh -c 'echo "MANGO"; echo; echo "  Super+Enter      terminal"; echo "  Super+D          launcher (type hyprland to switch back)"; echo "  Super+Q          close a window"; echo "  Super+1 to 9     tags (workspaces)"; echo; echo "  Super+Ctrl+H     back to Hyprland (Lelouch rice)"; echo "  Super+Shift+E    back to Hyprland (Lelouch rice)"; echo; echo "Press Enter to close this window."; read -r _' &
      fi
    '';
  };
}
