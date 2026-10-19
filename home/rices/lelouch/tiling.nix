{ config, lib, ... }:

let
  state = "${config.home.homeDirectory}/.local/state/lelouch";
in
{
  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    local layout_ok, layout_saved = pcall(dofile, "${state}/layout.lua")
    if layout_ok and (layout_saved == "dwindle" or layout_saved == "master" or layout_saved == "scrolling" or layout_saved == "monocle") then
        hl.config({ general = { layout = layout_saved } })
    end
  '';
}
