{ pkgs, ... }:

{
  home.packages = with pkgs; [
    btop
    fastfetch
    mpv
    imv
    yazi
    fetch
  ];

programs.obsidian = {
    enable = true;

    vaults.notes.target = "Documents/Obsidian";

    defaultSettings.app = {
      alwaysUpdateLinks = true;
      spellcheck = true;
    };
  };
}
