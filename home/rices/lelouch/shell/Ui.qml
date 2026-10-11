pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shared UI state
Singleton {
    id: root

    property bool volumeOpen: false
    property bool centerOpen: false
    property string centerPage: "system"

    // Keeps the screen awake: a systemd idle inhibitor (hypridle respects it) held while this is on
    property bool idleInhibit: false

    // Open the command center on a page; clicking the same item again closes it
    function toggleCenter(page) {
        volumeOpen = false;
        if (centerOpen && centerPage === page) {
            centerOpen = false;
        } else {
            centerPage = page;
            centerOpen = true;
        }
    }

    Process {
        running: root.idleInhibit
        command: ["systemd-inhibit", "--what=idle", "--who=Command Center", "--why=Idle inhibitor is on", "--mode=block", "sleep", "infinity"]
    }
}
