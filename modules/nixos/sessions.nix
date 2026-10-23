{ lib, pkgs, ... }:

# One login session that starts whichever desktop you chose last. The lock screen (or `switch-session`) records the
# choice in ~/.config/lelouch/session and ends the running session; with auto-login and Relogin on, the display
# manager logs straight back in and this wrapper starts the chosen desktop, which brings its own rice with it.
let
  start = pkgs.writeShellScript "lelouch-session" ''
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnused ]}:$PATH
    dir=/run/current-system/sw/share/wayland-sessions
    choice="$(cat "$HOME/.config/lelouch/session" 2>/dev/null)"
    if [ -z "$choice" ] || [ "$choice" = lelouch ] || [ ! -f "$dir/$choice.desktop" ]; then
      choice=hyprland
    fi
    file="$dir/$choice.desktop"
    cmd="$(sed -n 's/^Exec=//p' "$file" | head -n 1)"
    names="$(sed -n 's/^DesktopNames=//p' "$file" | head -n 1 | tr ';' ':')"
    export XDG_SESSION_DESKTOP="$choice"
    export XDG_CURRENT_DESKTOP="''${names%:}"
    [ -n "$XDG_CURRENT_DESKTOP" ] || export XDG_CURRENT_DESKTOP="$choice"
    exec sh -c "$cmd"
  '';
in
{
  services.displayManager.sessionPackages = [
    ((pkgs.writeTextDir "share/wayland-sessions/lelouch.desktop" ''
      [Desktop Entry]
      Name=Last used desktop
      Comment=Starts the desktop chosen in the lock screen, with its rice
      Exec=${start}
      Type=Application
    '') // { providedSessions = [ "lelouch" ]; })
  ];

  services.displayManager.defaultSession = lib.mkForce "lelouch";

  # After a logout, log straight back in: this is what makes switching desktops seamless
  services.displayManager.sddm.settings.Autologin.Relogin = true;
}
