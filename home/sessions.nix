{ pkgs, ... }:

let
  switch = pkgs.writeShellApplication {
    name = "switch-session";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      # switch-session [--relock] NAME: end this session and start desktop NAME (with its rice) in its place.
      # --relock: lock the new session as soon as it starts (used when switching from a lock screen).
      relock=0
      if [ "''${1:-}" = "--relock" ]; then
        relock=1
        shift
      fi
      name="''${1:-}"
      dir=/run/current-system/sw/share/wayland-sessions

      available=""
      for f in "$dir"/*.desktop; do
        n="$(basename "$f" .desktop)"
        [ "$n" = lelouch ] || available="$available $n"
      done

      if [ -z "$name" ] || [ "$name" = lelouch ] || [ ! -f "$dir/$name.desktop" ]; then
        echo "usage: switch-session [--relock] NAME   (one of:$available)" >&2
        exit 1
      fi

      if [ "''${XDG_SESSION_DESKTOP:-}" = "$name" ]; then
        echo "already in $name" >&2
        exit 0
      fi

      mkdir -p "$HOME/.config/lelouch" "$HOME/.cache/lelouch"
      printf '%s\n' "$name" > "$HOME/.config/lelouch/session"
      if [ "$relock" = 1 ]; then
        touch "$HOME/.cache/lelouch/relock"
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

  # Hyprland (the Lelouch rice) locks on arrival when it was switched to from a lock screen
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
        hl.exec_cmd("relock-if-flagged 3")
    end)
  '';
}
