{ pkgs, ... }:

{
  home.packages = with pkgs; [
    swaybg
    procps

    # wallpaper            -> random wallpaper + recolor everything
    # wallpaper <file>     -> specific wallpaper
    # wallpaper restore    -> used at login
    # Recoloring is done by `recolor`, which each rice provides.
    (writeShellApplication {
      name = "wallpaper";
      runtimeInputs = [ swaybg procps ];
      text = ''
        dir="$HOME/Pictures/Wallpapers"
        state="$HOME/.cache/current-wallpaper"

        if [ "''${1:-}" = "restore" ]; then
          img="$(cat "$state")"
          setsid -f swaybg -i "$img" -m fill
          exit 0
        fi

        if [ -n "''${1:-}" ]; then
          img="$1"
        else
          img="$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n 1)"
        fi

        if [ -z "$img" ]; then
          echo "No wallpapers found in $dir"
          exit 1
        fi

        echo "$img" > "$state"
        recolor "$img" || echo "recolor failed" >&2
        pkill swaybg || true
        setsid -f swaybg -i "$img" -m fill
        hyprctl reload > /dev/null || true
      '';
    })
  ];
}
