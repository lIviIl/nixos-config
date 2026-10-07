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

  # Gold trim into violet
  xdg.configFile."wal/templates/colors-hypr.lua".text = ''
    return {{
      active = {{ "rgba({color3.strip}ff)", "rgba({color5.strip}ff)" }},
      inactive = "rgba({color8.strip}55)",
    }}
  '';
}
