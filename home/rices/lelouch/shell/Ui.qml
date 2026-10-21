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

    // calendar, media, layout, alerts, focus or notes
    property string popup: ""

    // Screen x of the bar item that opened the current panel; -1 when a shortcut did (the panel then opens at its home)
    property real anchorX: -1

    // The open panel's left and right edges, so notifications can step aside
    property real surfaceLeft: 0
    property real surfaceRight: 0

    // Keeps the screen awake: a systemd idle inhibitor (hypridle respects it) held while this is on
    property bool idleInhibit: false

    readonly property bool anyOpen: volumeOpen || centerOpen || popup !== ""

    // How far notifications move left so an open panel doesn't cover them (a toast is 380 px wide, 12 px from the edge)
    readonly property real rightInset: {
        const screenWidth = Quickshell.screens.length > 0 ? Quickshell.screens[0].width : 1920;
        if (volumeOpen)
            return 324;
        if ((centerOpen || (popup !== "" && popup !== "notes")) && surfaceRight > screenWidth - 12 - 380 - 12)
            return screenWidth - surfaceLeft;
        return 0;
    }

    // from: a bar item (the panel opens under it), "right" (the right edge), or nothing (the panel's home)
    function anchorTo(from) {
        if (from && from.mapToItem)
            anchorX = from.mapToItem(null, from.width / 2, 0).x + 12;
        else if (from === "right")
            anchorX = 100000;
        else
            anchorX = -1;
    }

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
    function toggleCenter(page, from) {
        if (from !== undefined)
            anchorTo(from);
        volumeOpen = false;
        popup = "";
        if (centerOpen && centerPage === page) {
            centerOpen = false;
        } else {
            centerPage = page;
            centerOpen = true;
        }
    }

    function togglePopup(name, from) {
        if (from !== undefined)
            anchorTo(from);
        volumeOpen = false;
        centerOpen = false;
        popup = popup === name ? "" : name;
    }

    Process {
        running: root.idleInhibit
        command: ["systemd-inhibit", "--what=idle", "--who=Command Center", "--why=Idle inhibitor is on", "--mode=block", "sleep", "infinity"]
    }
}
