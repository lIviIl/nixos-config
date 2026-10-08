{ pkgs, ... }:

{
  home.packages = [
    pkgs.matugen

    # Called by `wallpaper`. --prefer saturation picks the source color automatically
    # (without it matugen asks, and fails when there is no terminal).
    # Other schemes to try: scheme-content, scheme-expressive, scheme-fidelity, scheme-rainbow
    (pkgs.writeShellScriptBin "recolor" ''
      mkdir -p "$HOME/.cache/matugen"
      exec ${pkgs.matugen}/bin/matugen image "$1" -m dark --type scheme-tonal-spot --prefer saturation
    '')
  ];

  xdg.configFile."matugen/config.toml".text = ''
    [config]

    # Blended toward the wallpaper's palette so they always look cohesive
    [config.custom_colors]
    gold    = { color = "#d4af37", blend = true }
    red     = { color = "#e05561", blend = true }
    green   = { color = "#6fcf97", blend = true }
    yellow  = { color = "#e5c07b", blend = true }
    blue    = { color = "#61afef", blend = true }
    magenta = { color = "#c678dd", blend = true }
    cyan    = { color = "#56b6c2", blend = true }

    [templates.quickshell]
    input_path = '~/.config/matugen/templates/colors.json'
    output_path = '~/.cache/matugen/colors.json'

    [templates.hyprland]
    input_path = '~/.config/matugen/templates/colors-hypr.lua'
    output_path = '~/.cache/matugen/colors-hypr.lua'

    [templates.kitty]
    input_path = '~/.config/matugen/templates/colors-kitty.conf'
    output_path = '~/.cache/matugen/colors-kitty.conf'
    post_hook = 'pkill -USR1 kitty'
  '';

  xdg.configFile."matugen/templates/colors.json".text = ''
    {
      "background": "{{ colors.surface.default.hex }}",
      "foreground": "{{ colors.on_surface.default.hex }}",
      "primary": "{{ colors.primary.default.hex }}",
      "onPrimary": "{{ colors.on_primary.default.hex }}",
      "outline": "{{ colors.outline.default.hex }}",
      "gold": "{{ colors.gold.default.hex }}"
    }
  '';

  # Gold trim into the primary color
  xdg.configFile."matugen/templates/colors-hypr.lua".text = ''
    return {
      active = { "rgba({{ colors.gold.default.hex_stripped }}ff)", "rgba({{ colors.primary.default.hex_stripped }}ff)" },
      inactive = "rgba({{ colors.outline_variant.default.hex_stripped }}cc)",
    }
  '';

  xdg.configFile."matugen/templates/colors-kitty.conf".text = ''
    foreground              {{ colors.on_surface.default.hex }}
    background              {{ colors.surface.default.hex }}
    selection_foreground    {{ colors.on_primary.default.hex }}
    selection_background    {{ colors.primary.default.hex }}
    cursor                  {{ colors.primary.default.hex }}
    url_color               {{ colors.tertiary.default.hex }}

    color0  {{ colors.surface_container_high.default.hex }}
    color8  {{ colors.outline.default.hex }}
    color1  {{ colors.red.default.hex }}
    color9  {{ colors.red.default.hex }}
    color2  {{ colors.green.default.hex }}
    color10 {{ colors.green.default.hex }}
    color3  {{ colors.yellow.default.hex }}
    color11 {{ colors.yellow.default.hex }}
    color4  {{ colors.blue.default.hex }}
    color12 {{ colors.blue.default.hex }}
    color5  {{ colors.magenta.default.hex }}
    color13 {{ colors.magenta.default.hex }}
    color6  {{ colors.cyan.default.hex }}
    color14 {{ colors.cyan.default.hex }}
    color7  {{ colors.on_surface_variant.default.hex }}
    color15 {{ colors.on_surface.default.hex }}
  '';
}
