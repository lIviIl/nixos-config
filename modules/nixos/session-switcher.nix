{ pkgs, ... }:

# NOT imported by default. It adds a login session called "lelouch" that starts whichever session
# you picked in the lock screen (stored in ~/.config/lelouch/session), falling back to Hyprland.
# To use it: add ../../modules/nixos/session-switcher.nix to the imports in hosts/nixos/default.nix,
# and set services.displayManager.defaultSession = "lelouch"; once you have a second session installed.
let
  start = pkgs.writeShellScript "lelouch-session" ''
    choice="$(cat "$HOME/.config/lelouch/session" 2>/dev/null)"
    file="/run/current-system/sw/share/wayland-sessions/$choice.desktop"
    if [ -n "$choice" ] && [ -f "$file" ]; then
      cmd="$(sed -n 's/^Exec=//p' "$file" | head -n 1)"
      exec sh -c "$cmd"
    fi
    exec Hyprland
  '';
in
{
  services.displayManager.sessionPackages = [
    ((pkgs.writeTextDir "share/wayland-sessions/lelouch.desktop" ''
      [Desktop Entry]
      Name=Lelouch (chosen in the lock screen)
      Comment=Starts the session picked in the lock screen
      Exec=${start}
      Type=Application
    '') // { providedSessions = [ "lelouch" ]; })
  ];
}
