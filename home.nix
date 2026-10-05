{ pkgs, ... }:

{
  home.username = "Vi";
  home.homeDirectory = "/home/Vi";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    pywal16
    pywalfox-native
    imagemagick
    swaybg
    rofi
    procps

    # wallpaper            -> random wallpaper + recolor everything
    # wallpaper <file>     -> specific wallpaper
    # wallpaper restore    -> used at login
    (writeShellApplication {
      name = "wallpaper";
      runtimeInputs = [ pywal16 swaybg procps pywalfox-native ];
      text = ''
        dir="$HOME/Pictures/Wallpapers"
        state="$HOME/.cache/current-wallpaper"

        if [ "''${1:-}" = "restore" ]; then
          img="$(cat "$state")"
          setsid -f swaybg -i "$img" -m fill
          exit 0
        fi

        if [ -n "''${1:-}" ]; then
          img="$1"
        else
          img="$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n 1)"
        fi

        if [ -z "$img" ]; then
          echo "No wallpapers found in $dir"
          exit 1
        fi

        echo "$img" > "$state"
        wal -n -q -i "$img"
        pkill swaybg || true
        setsid -f swaybg -i "$img" -m fill
        pkill -SIGUSR2 -f waybar || true
        hyprctl reload > /dev/null || true
        pywalfox update > /dev/null 2>&1 || true
      '';
    })
  ];

  # ---- Git ----
  programs.git = {
    enable = true;
    settings = {
      user.name = "lIviIl";
      user.email = "4aser.mo@gmail.com";
      init.defaultBranch = "main";
    };
  };

  # ---- Terminal ----
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      background_opacity = "0.85";
      window_padding_width = 12;
      confirm_os_window_close = 0;
    };
    extraConfig = "include /home/Vi/.cache/wal/colors-kitty.conf";
  };

  # ---- Browser ----
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.pywalfox-native ];
  };

  # ---- Notifications ----
  services.mako.enable = true;

  # ---- Bar ----
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      margin-top = 8;
      margin-left = 12;
      margin-right = 12;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      clock.format = "{:%a %d %b   %H:%M}";
      pulseaudio.format = "VOL {volume}%";
      network = {
        format-wifi = "{essid}";
        format-ethernet = "wired";
        format-disconnected = "offline";
      };
      battery.format = "BAT {capacity}%";
    };
    style = ''
      @import "/home/Vi/.cache/wal/colors-waybar.css";

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        border: none;
        min-height: 0;
      }

      window#waybar {
        background: alpha(@background, 0.8);
        color: @foreground;
        border-radius: 12px;
        border: 2px solid @color4;
      }

      #workspaces button {
        color: @foreground;
        padding: 0 10px;
        background: transparent;
      }

      #workspaces button.active {
        background: @color4;
        color: @background;
        border-radius: 8px;
      }

      #clock, #battery, #pulseaudio, #network, #tray {
        padding: 0 12px;
      }
    '';
  };

  # ---- Launcher (Rofi) ----
  xdg.configFile."rofi/config.rasi".text = ''
    @import "/home/Vi/.cache/wal/colors-zangetsu.rasi"

    configuration {
      modi: "drun";
      show-icons: false;
      font: "JetBrainsMono Nerd Font 12";
    }

    window {
      width: 520px;
      background-color: @bg;
      border: 2px;
      border-color: @accent;
      border-radius: 14px;
    }

    mainbox {
      padding: 14px;
      background-color: transparent;
    }

    inputbar {
      padding: 10px;
      background-color: transparent;
      text-color: @fg;
      children: [ prompt, entry ];
    }

    prompt {
      text-color: @accent;
      padding: 0 8px 0 0;
    }

    entry {
      text-color: @fg;
    }

    listview {
      lines: 7;
      padding: 8px 0 0 0;
      background-color: transparent;
    }

    element {
      padding: 8px;
      border-radius: 8px;
      background-color: transparent;
      text-color: @fg;
    }

    element selected.normal {
      background-color: @accent;
      text-color: @bg;
    }

    element-text {
      background-color: inherit;
      text-color: inherit;
    }
  '';

  # ---- pywal templates (curly braces doubled on purpose) ----
  xdg.configFile."wal/templates/colors-zangetsu.rasi".text = ''
    * {{
      bg: {background};
      fg: {foreground};
      accent: {color4};
      dim: {color8};
    }}
  '';

  xdg.configFile."wal/templates/colors-hypr.conf".text = ''
    general {{
      col.active_border = rgb({color4.strip})
      col.inactive_border = rgb({color0.strip})
    }}
  '';

  # ---- Hyprland ----
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    package = null;
    portalPackage = null;

    settings = {
      "$mod" = "SUPER";
      monitor = ",preferred,auto,1";

      exec-once = [
        "waybar"
        "wallpaper restore"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = "rgb(f2efe6)";
        "col.inactive_border" = "rgb(2a2a2e)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
        };
      };

      animations.enabled = true;

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      input.touchpad = {
        natural_scroll = true;
        tap-to-click = true;
      };

      bind = [
        "$mod, Return, exec, kitty"
        "$mod, D, exec, rofi -show drun"
        "$mod, F, exec, firefox"
        "$mod, W, exec, wallpaper"
        "$mod, Q, killactive,"
        "$mod, V, togglefloating,"
        "$mod, M, fullscreen,"
        "$mod SHIFT, E, exit,"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
      ] ++ (builtins.concatLists (builtins.genList (i:
        let ws = toString (i + 1); in [
          "$mod, ${ws}, workspace, ${ws}"
          "$mod SHIFT, ${ws}, movetoworkspace, ${ws}"
        ]) 9));

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

    # Wallpaper-derived border colors override the defaults above
    extraConfig = "source = /home/Vi/.cache/wal/colors-hypr.conf";
  };
}
