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
    grim
    slurp
    wl-clipboard
    fastfetch

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
      window_padding_width = 16;
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

    services.network-manager-applet.enable = true;

  programs.hyprlock.enable = true;

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  # ---- Bar ----
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 36;
      margin-top = 10;
      margin-left = 16;
      margin-right = 16;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = "I";
          "2" = "II";
          "3" = "III";
          "4" = "IV";
          "5" = "V";
        };
        persistent-workspaces = { "*" = 5; };
      };

      clock = {
        format = "{:%H:%M}";
        tooltip-format = "{:%A, %d %B %Y}";
      };
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
        background: transparent;
        color: @foreground;
      }

      #workspaces, #clock, #pulseaudio, #network, #battery, #tray {
        background: alpha(@background, 0.72);
        border: 1px solid alpha(@color5, 0.55);
        border-radius: 14px;
        padding: 0 14px;
        margin: 0 4px;
      }

      #workspaces {
        padding: 0 6px;
      }

      #workspaces button {
        padding: 0 10px;
        color: alpha(@foreground, 0.45);
        background: transparent;
      }

      #workspaces button.active {
        color: @foreground;
        background: alpha(@color5, 0.35);
        border-radius: 10px;
      }

      #clock {
        font-family: "Noto Serif";
        font-size: 15px;
        letter-spacing: 2px;
      }

      #battery.critical {
        color: #ff6b81;
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
      display-drun: "鏡花水月";
    }

    window {
      width: 560px;
      background-color: @bg;
      border: 1px;
      border-color: @accent;
      border-radius: 18px;
    }

    mainbox {
      padding: 22px;
      spacing: 14px;
      background-color: transparent;
    }

    inputbar {
      padding: 10px 6px;
      spacing: 12px;
      background-color: transparent;
      text-color: @fg;
      border: 0 0 1px 0;
      border-color: @dim;
      children: [ prompt, entry ];
    }

    prompt {
      text-color: @accent;
      background-color: transparent;
    }

    entry {
      text-color: @fg;
      background-color: transparent;
    }

    listview {
      lines: 6;
      spacing: 4px;
      background-color: transparent;
    }

    element {
      padding: 10px 12px;
      border-radius: 10px;
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
      col.active_border = rgb({color4.strip}) rgb({color5.strip}) 45deg
      col.inactive_border = rgba({color8.strip}55)
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
        gaps_in = 6;
        gaps_out = 16;
        border_size = 1;
        "col.active_border" = "rgb(d9d2f0)";
        "col.inactive_border" = "rgba(ffffff22)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 14;
        active_opacity = 1.0;
        inactive_opacity = 0.92;
        blur = {
          enabled = true;
          size = 8;
          passes = 3;
        };
        shadow = {
          enabled = true;
          range = 24;
          render_power = 3;
          color = "rgba(00000066)";
        };
      };

      animations = {
        enabled = true;
        bezier = [ "calm, 0.22, 1, 0.36, 1" ];
        animation = [
          "windows, 1, 6, calm, popin 90%"
          "fade, 1, 6, calm"
          "workspaces, 1, 7, calm, fade"
        ];
      };

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
        "$mod, L, exec, hyprlock"
        "$mod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
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
