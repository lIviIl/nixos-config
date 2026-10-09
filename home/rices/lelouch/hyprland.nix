{ config, ... }:

let
  colorDir = "${config.home.homeDirectory}/.cache/matugen";
in
{
  wayland.windowManager.hyprland.extraConfig = ''
    -- Border colors come from matugen (gold into primary); similar tones until the first wallpaper is set
    local colors = {
        active   = { "rgba(c9a227ff)", "rgba(8b5cf6ff)" },
        inactive = "rgba(3a3550cc)",
    }
    local ok, palette = pcall(dofile, "${colorDir}/colors-hypr.lua")
    if ok and type(palette) == "table" then
        colors = palette
    end

    hl.config({
        general = {
            gaps_in     = 5,
            gaps_out    = 12,
            border_size = 2,
            layout      = "dwindle",
            col = {
                active_border   = { colors = colors.active, angle = 45 },
                inactive_border = colors.inactive,
            },
        },

        decoration = {
            rounding         = 0,
            active_opacity   = 1.0,
            inactive_opacity = 0.94,
            shadow = {
                enabled      = true,
                range        = 14,
                render_power = 3,
                color        = 0x66000000,
            },
            blur = {
                enabled = true,
                size    = 6,
                passes  = 1,
            },
        },

        animations = {
            enabled = true,
        },

        misc = {
            disable_hyprland_logo = true,
        },
    })

    -- Curves (speed is in units of 100 ms)
    hl.curve("md3_decel", { type = "bezier", points = { {0.05, 0.7},  {0.1, 1.0}  } })
    hl.curve("overshoot", { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05} } })

    -- Windows: quick pop with a slight overshoot in, clean decel out
    hl.animation({ leaf = "windowsIn",  enabled = true, speed = 2.5, bezier = "overshoot", style = "popin 85%" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 2,   bezier = "md3_decel", style = "popin 85%" })
    hl.animation({ leaf = "fade",       enabled = true, speed = 2.5, bezier = "md3_decel" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 3,   bezier = "md3_decel", style = "slide" })

    -- The shell's overlays animate themselves, so don't animate layer surfaces twice
    hl.animation({ leaf = "layers", enabled = false, speed = 1, bezier = "md3_decel" })
  '';
}
