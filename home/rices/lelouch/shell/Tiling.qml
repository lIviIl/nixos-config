pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The layout Hyprland tiles windows with. It is applied live with `hyprctl eval`, and remembered in a small Lua file
// that the Hyprland config loads (see tiling.nix), so it survives reloads and reboots.
Singleton {
    id: root

    readonly property var layouts: [
        { id: "dwindle", label: "DWINDLE", hint: "Each new window splits the focused one in two" },
        { id: "master", label: "MASTER", hint: "One large window, the others stacked beside it" },
        { id: "scrolling", label: "SCROLLING", hint: "Columns on an endless strip you scroll along" },
        { id: "monocle", label: "MONOCLE", hint: "One window at a time, full size" }
    ]

    property string current: "dwindle"

    readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/lelouch/layout.lua"

    function set(id) {
        if (!layouts.some(l => l.id === id))
            return;
        current = id;
        Quickshell.execDetached(["hyprctl", "eval", 'hl.config({ general = { layout = "' + id + '" } })']);
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "return \\"%s\\"\\n" "$1" > "$2"', "sh", id, stateFile]);
    }

    function cycle() {
        const i = layouts.findIndex(l => l.id === current);
        set(layouts[(i + 1) % layouts.length].id);
    }

    // What Hyprland is using right now
    Process {
        id: probe
        command: ["hyprctl", "getoption", "general:layout"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/str:\s*(\w+)/);
                if (m)
                    root.current = m[1];
            }
        }
    }

    Component.onCompleted: probe.running = true
}
