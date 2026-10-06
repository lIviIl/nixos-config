{ pkgs, ... }:

{
  home.packages = [
    # wallpaper-pick -> Rofi thumbnail grid of ~/Pictures/Wallpapers
    (pkgs.writeShellApplication {
      name = "wallpaper-pick";
      runtimeInputs = [ pkgs.rofi pkgs.imagemagick pkgs.findutils pkgs.coreutils ];
      text = ''
        dir="$HOME/Pictures/Wallpapers"
        cache="$HOME/.cache/wallpaper-thumbs"
        mkdir -p "$cache"

        choice="$(
          while IFS= read -r -d "" f; do
            name="$(basename "$f")"
            thumb="$cache/$name.png"
            if [ ! -f "$thumb" ]; then
              magick "$f" -thumbnail 320x180^ -gravity center -extent 320x180 "$thumb"
            fi
            printf '%s\0icon\037%s\n' "$name" "$thumb"
          done < <(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0) \
            | rofi -dmenu -i -show-icons -p "嘘喰い" \
                -theme-str "window { width: 900px; } listview { columns: 3; lines: 2; } element { orientation: vertical; } element-icon { size: 9em; } element-text { horizontal-align: 0.5; }"
        )" || exit 0

        [ -n "$choice" ] || exit 0
        wallpaper "$dir/$choice"
      '';
    })
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("wallpaper-pick"))
  '';
}
