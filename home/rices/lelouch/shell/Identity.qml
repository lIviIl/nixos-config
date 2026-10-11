pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Who and what this session is, for the identity banner.
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") || "user"
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string desktop: Quickshell.env("XDG_CURRENT_DESKTOP") || "Hyprland"

    property string hostname: ""
    property string kernel: ""
    property real uptime: 0
    property real uptimeBase: 0
    property real uptimeStamp: 0

    Process {
        id: probe
        command: ["sh", "-c", "cat /proc/sys/kernel/hostname; cat /proc/sys/kernel/osrelease; cut -d' ' -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.split("\n");
                root.hostname = (l[0] || "").trim();
                root.kernel = (l[1] || "").trim();
                root.uptimeBase = parseFloat(l[2]) || 0;
                root.uptimeStamp = Date.now();
                root.uptime = root.uptimeBase;
            }
        }
    }

    // One read when the drawer opens, then count locally
    Connections {
        target: Ui

        function onCenterOpenChanged() {
            if (Ui.centerOpen && !probe.running)
                probe.running = true;
        }
    }

    Timer {
        interval: 1000
        running: Ui.centerOpen
        repeat: true
        onTriggered: root.uptime = root.uptimeBase + (Date.now() - root.uptimeStamp) / 1000
    }

    Component.onCompleted: probe.running = true
}
