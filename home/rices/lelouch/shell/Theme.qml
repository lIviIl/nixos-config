pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    FileView {
        id: walFile
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    // pywal's colors.json, or null until the first wallpaper has been set
    readonly property var wal: {
        try {
            return JSON.parse(walFile.text());
        } catch (e) {
            return null;
        }
    }

    // Fallbacks: imperial violet, ivory, gold
    readonly property color bg:        wal ? wal.special.background : "#120d1f"
    readonly property color fg:        wal ? wal.special.foreground : "#f1ecff"
    readonly property color gold:      wal ? wal.colors.color3 : "#c9a227"
    readonly property color primary:   wal ? wal.colors.color4 : "#8b5cf6"
    readonly property color secondary: wal ? wal.colors.color5 : "#b46bd6"
    readonly property color danger:    "#e0364f"

    readonly property string serif: "Noto Serif"
    readonly property string mono:  "JetBrainsMono Nerd Font"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
