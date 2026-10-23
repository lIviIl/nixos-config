{ ... }:

{
  imports = [
    ./git.nix
    ./firefox.nix
    ./packages.nix
    ./apps.nix
    ./desktop
    ./rices/lelouch   # <- change this line to switch rice
    ./rices/mango
    ./sessions.nix
  ];

  home.username = "Vi";
  home.homeDirectory = "/home/Vi";
  home.stateVersion = "26.05";
}
