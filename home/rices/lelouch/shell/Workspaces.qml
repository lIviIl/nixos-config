import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspaces 1-5 are always shown; 6-10 appear while they are in use.
Pill {
    id: root

    padding: 6
    contentSpacing: 2

    readonly property var labels: ["K", "Q", "R", "B", "N", "P", "VII", "VIII", "IX", "X"]

    Repeater {
        model: 10

        Rectangle {
            id: tile

            required property int index
            readonly property int n: index + 1
            readonly property var matches: Hyprland.workspaces.values.filter(w => w.id === n)
            readonly property bool exists: matches.length > 0
            readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === n

            visible: n <= 5 || exists
            width: Math.max(28, label.implicitWidth + 16)
            height: 24
            radius: 6
            color: focused ? Theme.primary : "transparent"

            Behavior on color { ColorAnimation { duration: 250 } }

            BarText {
                id: label
                anchors.centerIn: parent
                text: root.labels[tile.n - 1]
                color: tile.focused ? Theme.bg : Theme.alpha(Theme.fg, tile.exists ? 0.85 : 0.35)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + tile.n + " })"])
            }
        }
    }
}
