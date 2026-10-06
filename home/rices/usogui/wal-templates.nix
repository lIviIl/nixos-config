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

  xdg.configFile."wal/templates/colors-hypr.lua".text = ''
    return {{
      active = {{ "rgba({color4.strip}ff)", "rgba({foreground.strip}ff)" }},
      inactive = "rgba({color8.strip}66)",
    }}
  '';
}
