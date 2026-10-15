{ lib, pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: [ ps.icalendar ps.recurring-ical-events ]);
in
{
  home.packages = [
    # lelouch-agenda FROM TO   (dates as YYYY-MM-DD): your calendar's events as JSON,
    # recurring events expanded and times converted to local time
    (pkgs.writeShellScriptBin "lelouch-agenda" ''
      url_file="$HOME/.config/lelouch/calendar-url"
      if [ ! -r "$url_file" ]; then
        echo "no-url" >&2
        exit 3
      fi
      ${pkgs.curl}/bin/curl -fsSL --max-time 25 "$(cat "$url_file")" | ${python}/bin/python3 ${./ical.py} "$1" "$2"
    '')
  ];

  # The folders the shell keeps its data in (the two under Sync are what Syncthing shares)
  home.activation.lelouchDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Sync/todo" "$HOME/Sync/notes" "$HOME/.config/lelouch" "$HOME/.local/state/lelouch" "$HOME/.cache/lelouch"
  '';
}
