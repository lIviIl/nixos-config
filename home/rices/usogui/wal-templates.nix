{ ... }:

{
  # pywal templates: curly braces are doubled on purpose
  xdg.configFile."wal/templates/colors-rofi.rasi".text = ''
    * {{
      bg: {background};
      fg: {foreground};
      accent: {color4};
      dim: {color7};
    }}
  '';

  xdg.configFile."wal/templates/colors-hypr.conf".text = ''
    general {{
      col.active_border = rgb({color4.strip}) rgb({foreground.strip}) 45deg
      col.inactive_border = rgba({color8.strip}66)
    }}
  '';
}
