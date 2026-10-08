pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.cache/matugen/colors.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    // matugen's colors.json, or null until the first wallpaper has been set
    readonly property var palette: {
        try {
            return JSON.parse(paletteFile.text());
        } catch (e) {
            return null;
        }
    }

    // Fallbacks: imperial violet, ivory, gold
    readonly property color bg:        palette ? palette.background : "#120d1f"
    readonly property color fg:        palette ? palette.foreground : "#f1ecff"
    readonly property color gold:      palette ? palette.gold : "#c9a227"
    readonly property color primary:   palette ? palette.primary : "#8b5cf6"
    readonly property color onPrimary: palette ? palette.onPrimary : "#120d1f"
    readonly property color secondary: palette ? palette.secondary : "#b46bd6"
    readonly property color outline:   palette ? palette.outline : "#8a80a8"
    readonly property color danger:    palette ? palette.error : "#e0364f"

    // Geass red: constant, not taken from the wallpaper
    readonly property color crimson: "#c1121f"

    // How opaque the bar and cards are (lower shows more wallpaper)
    readonly property real glass: 0.80

    readonly property string serif: "Noto Serif"
    readonly property string mono:  "JetBrainsMono Nerd Font"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }
}
