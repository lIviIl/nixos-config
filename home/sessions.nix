{ pkgs, ... }:

let
  switch = pkgs.writeShellApplication {
    name = "switch-session";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      # switch-session [--relock] NAME: restart the computer into desktop NAME (with its rice).
      # --relock: lock the new session as soon as it starts (used when switching from a lock screen).
      # Ending one session and starting another live leaves a black screen on this laptop (the login screen
      # fails to start after a Wayland desktop ends), so this takes the path that always works: a restart.
      relock=0
      if [ "''${1:-}" = "--relock" ]; then
        relock=1
        shift
      fi
      name="''${1:-}"
      dir=/etc/lelouch/wayland-sessions

      available=""
      for f in "$dir"/*.desktop; do
        [ -e "$f" ] || continue
        n="$(basename "$f" .desktop)"
        [ "$n" = lelouch ] || available="$available $n"
      done

      if [ -z "$name" ] || [ "$name" = lelouch ] || [ ! -f "$dir/$name.desktop" ]; then
        echo "usage: switch-session [--relock] NAME   (one of:$available)" >&2
        exit 1
      fi

      current="$(printf '%s' "''${XDG_SESSION_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')"
      if [ "$current" = "$name" ]; then
        echo "already in $name" >&2
        exit 0
      fi

      mkdir -p "$HOME/.config/lelouch" "$HOME/.cache/lelouch"
      printf '%s\n' "$name" > "$HOME/.config/lelouch/session"
      if [ "$relock" = 1 ]; then
        touch "$HOME/.cache/lelouch/relock"
      fi

      echo "Saved: $name starts at the next login. Restarting..."
      exec systemctl reboot
    '';
  };

  relock = pkgs.writeShellApplication {
    name = "relock-if-flagged";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      # Called when a desktop starts: if the session was switched from a lock screen, lock it again
      flag="$HOME/.cache/lelouch/relock"
      [ -e "$flag" ] || exit 0
      rm -f "$flag"
      sleep "''${1:-3}"
      exec lock-screen
    '';
  };
in
{
  home.packages = [ switch relock ];

  # Launcher entries, so a switch is one search away in either desktop
  xdg.desktopEntries = {
    switch-to-hyprland = {
      name = "Switch to Hyprland (Lelouch rice, restarts)";
      exec = "switch-session hyprland";
      terminal = false;
      categories = [ "System" ];
    };
    switch-to-mango = {
      name = "Switch to Mango (restarts)";
      exec = "switch-session mango";
      terminal = false;
      categories = [ "System" ];
    };
  };

  # Hyprland (the Lelouch rice) locks on arrival when it was switched to from a lock screen
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
        hl.exec_cmd("relock-if-flagged 3")
    end)
  '';
}
