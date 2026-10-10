{ pkgs, ... }:

let
  capture = pkgs.writeShellApplication {
    name = "lelouch-capture";
    runtimeInputs = with pkgs; [ grim slurp wl-clipboard wf-recorder tesseract libnotify procps coreutils ];
    text = ''
      shots="$HOME/Pictures/Screenshots"
      videos="$HOME/Videos"
      mkdir -p "$shots" "$videos"
      stamp="$(date +%Y-%m-%d_%H-%M-%S)"

      case "''${1:-}" in
        full)
          file="$shots/$stamp.png"
          grim "$file"
          wl-copy < "$file"
          notify-send "Screenshot saved" "$file"
          ;;
        region)
          area="$(slurp)" || exit 0
          file="$shots/$stamp.png"
          grim -g "$area" "$file"
          wl-copy < "$file"
          notify-send "Region saved" "$file"
          ;;
        ocr)
          area="$(slurp)" || exit 0
          text="$(grim -g "$area" - | tesseract stdin stdout 2>/dev/null)"
          printf '%s' "$text" | wl-copy
          notify-send "Text copied" "$(printf '%s' "$text" | head -c 200)"
          ;;
        record)
          if pgrep -x wf-recorder > /dev/null; then
            pkill -INT -x wf-recorder
            notify-send "Recording saved" "$videos"
          else
            notify-send "Recording started" "Run again to stop"
            exec wf-recorder -f "$videos/$stamp.mp4"
          fi
          ;;
        *)
          echo "usage: lelouch-capture full|region|ocr|record" >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  home.packages = [ capture ];

  wayland.windowManager.hyprland.extraConfig = ''
    hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("lelouch-capture region"))
    hl.bind("Print", hl.dsp.exec_cmd("lelouch-capture full"))
    hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("lelouch-capture ocr"))
    hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("lelouch-capture record"))
  '';
}
