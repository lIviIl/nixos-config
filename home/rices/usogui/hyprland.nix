{ config, ... }:

let
  walDir = "${config.home.homeDirectory}/.cache/wal";
in
{
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
        hl.exec_cmd("waybar")
    end)

    -- Border colors come from pywal; white until the first wallpaper is set
    local colors = {
        active   = { "rgba(ffffffff)", "rgba(ffffffff)" },
        inactive = "rgba(ffffff22)",
    }
    local ok, wal = pcall(dofile, "${walDir}/colors-hypr.lua")
    if ok and type(wal) == "table" then
        colors = wal
    end

    hl.config({
        general = {
            gaps_in     = 4,
            gaps_out    = 10,
            border_size = 2,
            layout      = "dwindle",
            col = {
                active_border   = { colors = colors.active, angle = 45 },
                inactive_border = colors.inactive,
            },
        },

        decoration = {
            rounding         = 4,
            active_opacity   = 1.0,
            inactive_opacity = 0.94,
            shadow = {
                enabled      = true,
                range        = 16,
                render_power = 3,
                color        = 0x99000000,
            },
            blur = {
                enabled = true,
                size    = 5,
                passes  = 2,
            },
        },

        animations = {
            enabled = true,
        },

        misc = {
            disable_hyprland_logo = true,
        },
    })

    -- Snappy animations with a slight overshoot
    hl.curve("flick", { type = "bezier", points = { {0.2, 1.2}, {0.3, 1} } })

    hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4, bezier = "flick", style = "popin 80%" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "flick", style = "popin 80%" })
    hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "flick" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "flick", style = "slide" })
  '';
}
