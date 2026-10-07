{ config, ... }:

let
  walDir = "${config.home.homeDirectory}/.cache/wal";
in
{
  wayland.windowManager.hyprland.extraConfig = ''
    -- Border colors come from pywal (gold into violet); same tones until the first wallpaper is set
    local colors = {
        active   = { "rgba(c9a227ff)", "rgba(8b5cf6ff)" },
        inactive = "rgba(8a80a855)",
    }
    local ok, wal = pcall(dofile, "${walDir}/colors-hypr.lua")
    if ok and type(wal) == "table" then
        colors = wal
    end

    hl.config({
        general = {
            gaps_in     = 6,
            gaps_out    = 14,
            border_size = 2,
            layout      = "dwindle",
            col = {
                active_border   = { colors = colors.active, angle = 45 },
                inactive_border = colors.inactive,
            },
        },

        decoration = {
            rounding         = 12,
            active_opacity   = 1.0,
            inactive_opacity = 0.95,
            shadow = {
                enabled      = true,
                range        = 20,
                render_power = 3,
                color        = 0x99000000,
            },
            blur = {
                enabled = true,
                size    = 6,
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

    -- Deliberate, regal motion (no overshoot)
    hl.curve("regal", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })

    hl.animation({ leaf = "windowsIn",  enabled = true, speed = 5, bezier = "regal", style = "popin 90%" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "regal", style = "popin 90%" })
    hl.animation({ leaf = "fade",       enabled = true, speed = 5, bezier = "regal" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "regal", style = "slide" })
  '';
}
