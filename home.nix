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
    papirus-icon-theme
    bibata-cursors

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
        wal -n -q --saturate 0.6 -i "$img"
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
      background_opacity = "0.9";
      window_padding_width = 14;
      confirm_os_window_close = 0;
      cursor_shape = "block";
    };
    extraConfig = "include /home/Vi/.cache/wal/colors-kitty.conf";
  };

  # ---- Browser ----
  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.pywalfox-native ];
  };

  # ---- Notifications ----
  services.mako = {
    enable = true;
    settings = {
      font = "JetBrainsMono Nerd Font 11";
      background-color = "#0a0a0aee";
      text-color = "#f2f2f2";
      border-color = "#f2f2f2";
      border-size = 2;
      border-radius = 4;
      padding = 12;
      default-timeout = 5000;
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

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
      height = 38;
      margin-top = 8;
      margin-left = 12;
      margin-right = 12;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = "A";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
          "10" = "10";
          "11" = "J";
          "12" = "Q";
          "13" = "K";
          default = "·";
        };
        persistent-workspaces = { "*" = 5; };
      };

      clock = {
        format = "{:%H:%M}";
        tooltip-format = "{:%A, %d %B %Y}";
      };

      pulseaudio = {
        format = "VOL {volume}%";
        format-muted = "MUTED";
      };

      network = {
        format-wifi = "{essid}";
        format-ethernet = "wired";
        format-disconnected = "offline";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "BAT {capacity}%";
        format-charging = "CHG {capacity}%";
        format-plugged = "AC {capacity}%";
      };

      tray.spacing = 10;
    };
    style = ''
      @import "/home/Vi/.cache/wal/colors-waybar.css";

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
        font-weight: bold;
        border: none;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: @foreground;
      }

      #workspaces, #clock, #pulseaudio, #network, #battery, #tray {
        background: alpha(@background, 0.88);
        border: 2px solid @foreground;
        border-radius: 4px;
        padding: 0 14px;
        margin: 0 4px;
      }

      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        padding: 0 10px;
        margin: 3px 2px;
        color: alpha(@foreground, 0.5);
        background: transparent;
        border-radius: 3px;
        box-shadow: none;
        text-shadow: none;
      }

      #workspaces button:hover {
        color: @foreground;
        background: alpha(@color4, 0.3);
      }

      #workspaces button.active {
        color: @background;
        background: @color4;
      }

      #workspaces button.urgent {
        color: #ff4d5e;
      }

      #clock {
        letter-spacing: 3px;
      }

      #pulseaudio.muted {
        color: alpha(@foreground, 0.5);
      }

      #battery.warning {
        color: #ffd479;
      }

      #battery.critical {
        color: #ff4d5e;
      }
    '';
  };

  # ---- Launcher (Rofi) ----
  xdg.configFile."rofi/config.rasi".text = ''
    @import "/home/Vi/.cache/wal/colors-zangetsu.rasi"

    configuration {
      modi: "drun";
      show-icons: false;
      font: "JetBrainsMono Nerd Font Bold 13";
      display-drun: "嘘喰い";
      drun-display-format: "{name}";
    }

    window {
      width: 540px;
      background-color: @bg;
      border: 2px;
      border-color: @fg;
      border-radius: 4px;
    }

    mainbox {
      padding: 20px;
      spacing: 14px;
      background-color: transparent;
      children: [ inputbar, listview ];
    }

    inputbar {
      padding: 10px 6px;
      spacing: 12px;
      background-color: transparent;
      text-color: @fg;
      border: 0 0 2px 0;
      border-color: @accent;
      children: [ prompt, entry ];
    }

    prompt {
      text-color: @accent;
      background-color: transparent;
    }

    entry {
      text-color: @fg;
      background-color: transparent;
      placeholder: "place your bet";
      placeholder-color: @dim;
    }

    listview {
      lines: 6;
      spacing: 6px;
      scrollbar: false;
      fixed-height: false;
      border: 0;
      padding: 4px 0 0 0;
      background-color: transparent;
    }

    element {
      padding: 10px 12px;
      border-radius: 3px;
    }

    element normal.normal, element alternate.normal,
    element normal.active, element alternate.active,
    element normal.urgent, element alternate.urgent {
      background-color: transparent;
      text-color: @fg;
    }

    element selected.normal, element selected.active, element selected.urgent {
      background-color: @fg;
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
      col.active_border = rgb({color4.strip}) rgb({foreground.strip}) 45deg
      col.inactive_border = rgba({color8.strip}66)
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
        gaps_in = 4;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgb(ffffff)";
        "col.inactive_border" = "rgba(ffffff22)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 4;
        active_opacity = 1.0;
        inactive_opacity = 0.94;
        blur = {
          enabled = true;
          size = 5;
          passes = 2;
        };
        shadow = {
          enabled = true;
          range = 16;
          render_power = 3;
          color = "rgba(00000099)";
        };
      };

      animations = {
        enabled = true;
        bezier = [ "flick, 0.2, 1.2, 0.3, 1" ];
        animation = [
          "windows, 1, 4, flick, popin 80%"
          "fade, 1, 4, flick"
          "workspaces, 1, 5, flick, slide"
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

    # Wallpaper-derived border colors override the defaults above
    extraConfig = "source = /home/Vi/.cache/wal/colors-hypr.conf";
  };
}
