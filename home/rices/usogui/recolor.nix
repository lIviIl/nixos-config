{ pkgs, ... }:

{
  home.packages = [
    pkgs.pywal16
    pkgs.imagemagick

    (pkgs.writeShellScriptBin "recolor" ''
      ${pkgs.pywal16}/bin/wal -n -q --saturate 0.6 -i "$1"
      ${pkgs.procps}/bin/pkill -SIGUSR2 -f waybar || true
    '')
  ];
}
