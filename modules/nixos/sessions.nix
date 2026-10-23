{ config, lib, pkgs, ... }:

# One login session that starts whichever desktop you chose last. The lock screen (or `switch-session`) records the
# choice in ~/.config/lelouch/session and ends the running session; this wrapper then starts the chosen desktop, which
# brings its own rice with it.
let
  # false: after a switch the login screen appears and you type your password.
  # true:  log straight back in (no password) and lock the new session on arrival.
  # Turn this on only after one successful reboot test: a broken session would otherwise restart over and over.
  seamlessSwitch = false;

  start = pkgs.writeShellScript "lelouch-session" ''
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnused ]}:$PATH
    dir=/etc/lelouch/wayland-sessions

    choice="$(cat "$HOME/.config/lelouch/session" 2>/dev/null)"
    if [ -z "$choice" ] || [ "$choice" = lelouch ] || [ ! -f "$dir/$choice.desktop" ]; then
      choice=hyprland
    fi
    file="$dir/$choice.desktop"

    cmd=""
    names=""
    if [ -f "$file" ]; then
      cmd="$(sed -n 's/^Exec=//p' "$file" | head -n 1)"
      names="$(sed -n 's/^DesktopNames=//p' "$file" | head -n 1 | tr ';' ':')"
    fi

    # Never exit at once: if the list is missing or broken, start Hyprland
    if [ -z "$cmd" ]; then
      choice=hyprland
      cmd=Hyprland
      names=Hyprland
    fi

    export XDG_SESSION_DESKTOP="$choice"
    export XDG_CURRENT_DESKTOP="''${names%:}"
    [ -n "$XDG_CURRENT_DESKTOP" ] || export XDG_CURRENT_DESKTOP="$choice"

    # A test run: say what would start, and stop
    if [ -n "''${LELOUCH_DRY_RUN:-}" ]; then
      echo "choice=$choice cmd=$cmd desktop=$XDG_CURRENT_DESKTOP"
      exit 0
    fi

    started="$(date +%s)"
    sh -c "$cmd"
    status=$?

    # A desktop that dies within 8 seconds is probably broken: wait before the display manager can retry
    if [ $(( $(date +%s) - started )) -lt 8 ]; then
      sleep 45
    fi
    exit "$status"
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
  services.displayManager.sddm.settings.Autologin.Relogin = seamlessSwitch;

  # The installed desktops, at a stable path the lock screen and `switch-session` can read
  environment.etc."lelouch/wayland-sessions".source = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
  environment.etc."lelouch/seamless" = lib.mkIf seamlessSwitch { text = "on\n"; };
}
