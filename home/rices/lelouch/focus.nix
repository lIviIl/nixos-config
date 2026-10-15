{ pkgs, ... }:

let
  sounds = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo";
in
{
  home.packages = [
    # lelouch-chime done|break|alarm: a short sound for the Focus timers
    (pkgs.writeShellApplication {
      name = "lelouch-chime";
      runtimeInputs = [ pkgs.pulseaudio ];
      text = ''
        case "''${1:-done}" in
          break) file="${sounds}/message.oga" ;;
          alarm) file="${sounds}/alarm-clock-elapsed.oga" ;;
          *) file="${sounds}/complete.oga" ;;
        esac
        exec paplay "$file"
      '';
    })
  ];
}
