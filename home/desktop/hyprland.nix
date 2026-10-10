{ ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    # Use the Hyprland from the NixOS module so versions can't mismatch
    package = null;
    portalPackage = null;

    # Lua, appended to the file Home Manager generates.
    # Other modules (rofi, kitty, ...) append their own keybinds the same way.
    extraConfig = ''
      local mainMod = "SUPER"

      hl.monitor({
          output   = "",
          mode     = "preferred",
          position = "auto",
          scale    = 1,
      })

      hl.on("hyprland.start", function()
          hl.exec_cmd("wallpaper restore")
      end)

      hl.config({
          dwindle = {
              preserve_split = true,
          },
          input = {
              kb_layout = "us,ara",
              kb_options = "grp:alt_shift_toggle",
              touchpad = {
                  natural_scroll       = true,
                  tap_to_click         = true,
                  disable_while_typing = false,
              },
          },
      })

      hl.gesture({
          fingers   = 3,
          direction = "horizontal",
          action    = "workspace",
      })

      -- Hyprland 0.56 started honoring "launch maximized" requests from apps,
      -- which makes new windows cover the screen instead of tiling. Ignore them.
      hl.window_rule({
          name           = "suppress-maximize-events",
          match          = { class = ".*" },
          suppress_event = "maximize",
      })

      -- Windows
      hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
      hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + M",         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
      hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
      hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))
      hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
      hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("wallpaper"))

      -- Focus
      hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
      hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

      -- Workspaces 1-10 (key 0 is workspace 10)
      for i = 1, 10 do
          local key = i % 10
          hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
          hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end

      -- Step through workspaces (next one is created if needed)
      hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "+1" }))
      hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ workspace = "e-1" }))
      hl.bind(mainMod .. " + mouse_down",   hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mainMod .. " + mouse_up",     hl.dsp.focus({ workspace = "e-1" }))

      -- Move/resize with the mouse
      hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- Volume and brightness keys
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
      hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
      hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
    '';
  };
}
