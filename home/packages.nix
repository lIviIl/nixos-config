{ pkgs, ... }:

{
  home.packages = with pkgs; [
    btop
    fastfetch
    obsidian
    mpv
    imv
  ];
}
