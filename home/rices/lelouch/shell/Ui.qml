pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared UI state
Singleton {
    id: root

    property bool volumeOpen: false
    property bool centerOpen: false

    // Keeps the screen awake: a systemd idle inhibitor (hypridle respects it) held while this is on
    property bool idleInhibit: false

    Process {
        running: root.idleInhibit
        command: ["systemd-inhibit", "--what=idle", "--who=Command Center", "--why=Idle inhibitor is on", "--mode=block", "sleep", "infinity"]
    }
}
