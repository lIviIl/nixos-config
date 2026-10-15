{ pkgs, ... }:

{
  home.packages = [
    # The Quickshell lock screen, falling back to hyprlock if the shell isn't running
    (pkgs.writeShellScriptBin "lock-screen" ''
      ${pkgs.quickshell}/bin/quickshell -c lelouch ipc call lock lock || exec ${pkgs.hyprlock}/bin/hyprlock
    '')

    # lelouch-lockshot OUTPUT...: a screenshot of each output, taken just before the lock engages,
    # so the unlock can fade into the desktop as it was
    (pkgs.writeShellApplication {
      name = "lelouch-lockshot";
      runtimeInputs = [ pkgs.grim pkgs.coreutils ];
      text = ''
        dir="$HOME/.cache/lelouch"
        mkdir -p "$dir"
        for output in "$@"; do
          grim -t jpeg -q 85 -o "$output" "$dir/lockshot-$output.jpg" &
        done
        wait
      '';
    })
  ];
}
