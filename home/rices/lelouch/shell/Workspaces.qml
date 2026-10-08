import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspaces 1-5 are always shown; 6-10 appear while they are in use.
Row {
    id: root
    spacing: 2

    readonly property var labels: ["K", "Q", "R", "B", "N", "P", "VII", "VIII", "IX", "X"]

    Repeater {
        model: 10

        Item {
            id: tile

            required property int index
            readonly property int n: index + 1
            readonly property var matches: Hyprland.workspaces.values.filter(w => w.id === n)
            readonly property bool exists: matches.length > 0
            readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === n

            visible: n <= 5 || exists
            width: Math.max(30, label.implicitWidth + 18)
            height: 28

            // Active marker: primary fill with a crimson edge
            Chamfer {
                anchors.fill: parent
                cut: 5
                fillTop: Theme.primary
                strokeColor: Theme.crimson
                opacity: tile.focused ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            BarText {
                id: label
                anchors.centerIn: parent
                text: root.labels[tile.n - 1]
                color: tile.focused ? Theme.onPrimary : Theme.alpha(Theme.fg, tile.exists ? 0.9 : 0.4)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + tile.n + " })"])
            }
        }
    }
}
