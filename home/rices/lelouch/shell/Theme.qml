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
    readonly property color danger:    palette ? palette.error : "#e0364f"

    readonly property string serif: "Noto Serif"
    readonly property string mono:  "JetBrainsMono Nerd Font"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
