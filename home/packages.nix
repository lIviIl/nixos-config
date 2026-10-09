{ pkgs, ... }:

{
  home.packages = with pkgs; [
    btop
    fastfetch
    obsidian
    localsend
    mpv
    imv
  ];
}
