{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # A terminal app: tests the launcher's "run in terminal" path
    btop
    fastfetch
    # A few GUI apps to launch
    mpv
    imv
  ];
}
