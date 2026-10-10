{ pkgs, ... }:

{
  home.packages = with pkgs; [
    btop
    fastfetch
    mpv
    imv
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
