pragma Singleton

import QtQuick
import Quickshell

// State shared by every lock surface and the doors overlay
Singleton {
    id: root

    property bool locked: false
    property string typedText: ""        // never displayed; only its length drives the sigil
    readonly property int typed: typedText.length
    property bool granted: false
    property bool busy: false
    property int failPulse: 0            // incremented on every rejected attempt
    property string status: "STATE YOUR WILL"

    // Cursor position from the screen center, -1..1
    property real px: 0
    property real py: 0

    property date now: new Date()

    Timer {
        interval: 1000
        running: root.locked || root.granted
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
