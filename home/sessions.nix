{ pkgs, ... }:

let
  switch = pkgs.writeShellApplication {
    name = "switch-session";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      # switch-session [--relock] NAME: end this session; the next login starts desktop NAME (with its rice).
      # --relock: lock the new session on arrival (only when seamless switching is on).
      # From a text console (Ctrl+Alt+F2) it saves the choice and restarts the login screen.
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
      if [ "$relock" = 1 ] && [ -e /etc/lelouch/seamless ]; then
        touch "$HOME/.cache/lelouch/relock"
      fi

      if [ "''${XDG_SESSION_TYPE:-}" != wayland ]; then
        echo "Saved: $name starts at the next login. Restarting the login screen (asks for your password)..."
        exec sudo systemctl restart display-manager
      fi

      # The graphical session's id (the shell runs as a user service, which has no XDG_SESSION_ID of its own)
      sid="''${XDG_SESSION_ID:-$(loginctl show-user "$(id -un)" --property=Display --value)}"
      exec loginctl terminate-session "$sid"
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
      name = "Switch to Hyprland (Lelouch rice)";
      exec = "switch-session hyprland";
      terminal = false;
      categories = [ "System" ];
    };
    switch-to-mango = {
      name = "Switch to Mango";
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
