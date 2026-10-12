{ ... }:

{
  imports = [
    ./git.nix
    ./firefox.nix
    ./packages.nix
    ./desktop
    ./rices/usogui   # <- change this line to switch rice
  ];

  home.username = "Vi";
  home.homeDirectory = "/home/Vi";
  home.stateVersion = "26.05";
}
