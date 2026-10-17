pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What is open. Only one of the volume panel, the command center and a popup is open at a time.
Singleton {
    id: root

    property bool volumeOpen: false
    property bool centerOpen: false
    property string centerPage: "system"

    // calendar, media, alerts, focus or notes
    property string popup: ""

    // Keeps the screen awake: a systemd idle inhibitor (hypridle respects it) held while this is on
    property bool idleInhibit: false

    readonly property bool anyOpen: volumeOpen || centerOpen || popup !== ""

    // How much of the right edge the open surface covers (its width and the gaps), so notifications step aside
    readonly property real rightInset: volumeOpen ? 324 : (centerOpen ? 712 : (popup === "alerts" || popup === "focus" ? 484 : 0))

    function closeAll() {
        volumeOpen = false;
        centerOpen = false;
        popup = "";
    }

    function toggleVolume() {
        centerOpen = false;
        popup = "";
        volumeOpen = !volumeOpen;
    }

    // Open the command center on a page; clicking the same item again closes it
    function toggleCenter(page) {
        volumeOpen = false;
        popup = "";
        if (centerOpen && centerPage === page) {
            centerOpen = false;
        } else {
            centerPage = page;
            centerOpen = true;
        }
    }

    function togglePopup(name) {
        volumeOpen = false;
        centerOpen = false;
        popup = popup === name ? "" : name;
    }

    Process {
        running: root.idleInhibit
        command: ["systemd-inhibit", "--what=idle", "--who=Command Center", "--why=Idle inhibitor is on", "--mode=block", "sleep", "infinity"]
    }
}
