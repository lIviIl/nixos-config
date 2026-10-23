# The Mango rice

Mango is the window manager (a dwl-based Wayland compositor). This folder is the whole rice for the **mango**
session. It is separate from the **Lelouch** rice (`home/rices/lelouch`, the **hyprland** session): each rice runs
only under its own session, and the lock screen's session buttons (or `switch-session NAME`) move between them.

## Rules

1. Work only in this folder. Do not edit `home/rices/lelouch`, `home/desktop` or the lock screen shell.
2. Mango's settings go in `wayland.windowManager.mango` in `default.nix` (`settings`, `extraConfig`, `autostart_sh`).
   Repeated keys such as `bind` are lists. Options: https://github.com/mangowm/mango/wiki/nix-options
   Config reference: https://mangowm.github.io/docs  (`mmsg -d reload_config` or Super+R reloads it)
3. Start the rice's own services (bar, notifications, wallpaper, idle and lock daemon) from `autostart_sh`.
   Do not use `WantedBy = graphical-session.target` for them: that would also start them under Hyprland.
4. Keep `relock-if-flagged 3 &` in `autostart_sh` and the `switch-session hyprland` key, or there is no way back.
5. Shared settings: kitty, GTK (icons, cursor), Firefox and `home/packages.nix` are one user-wide config, so this
   rice inherits Lelouch's versions. To look different, apply them when Mango starts (for example `gsettings set
   org.gnome.desktop.interface ...` and `KITTY_CONFIG_DIRECTORY` in `autostart_sh`) instead of changing the
   global module, which would also change Lelouch.
6. Not set up: touchpad options (tap to click, natural scrolling), idle locking, a bar, wallpaper and notifications.
   `lock-screen` falls back to hyprlock here because Lelouch's own lock screen belongs to its Quickshell.
7. Rebuild with `rebuild`. Check everything with `bash scripts/verify.sh; bash scripts/verify-sessions.sh`.
