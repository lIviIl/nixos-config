{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pywal16
    imagemagick
    swaybg
    procps

    # wallpaper            -> random wallpaper + recolor everything
    # wallpaper <file>     -> specific wallpaper
    # wallpaper restore    -> used at login
    (writeShellApplication {
      name = "wallpaper";
      runtimeInputs = [ pywal16 swaybg procps pywalfox-native ];
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
        wal -n -q --saturate 0.6 -i "$img"
        pkill swaybg || true
        setsid -f swaybg -i "$img" -m fill
        pkill -SIGUSR2 -f waybar || true
        hyprctl reload > /dev/null || true
        pywalfox update > /dev/null 2>&1 || true
      '';
    })
  ];
}
