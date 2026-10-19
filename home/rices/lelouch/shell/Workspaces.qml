import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland

// Workspaces 1 to 5 are always shown; 6 to 10 appear while they are in use.
// Each one is drawn as a picture (assets/workspaces/<n>.svg or .png) if there is one, otherwise as its glyph below.
Row {
    id: root

    spacing: 2

    // Workspaces 1 to 10, in order. Any characters work (chess pieces, kanji, numerals, ...).
    readonly property var glyphs: ["♔", "♕", "♖", "♗", "♘", "♙", "♚", "♛", "♜", "♝"]

    // Recolour pictures with the theme (they should be one-colour shapes). false keeps their own colours.
    readonly property bool tintIcons: true

    Repeater {
        model: 10

        Item {
            id: tile

            required property int index

            readonly property int n: index + 1
            readonly property bool exists: Hyprland.workspaces.values.some(w => w.id === n)
            readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === n
            readonly property color ink: focused ? Theme.onPrimary : Theme.alpha(Theme.fg, exists ? 0.9 : 0.4)
            readonly property bool hasPicture: pic.status === Image.Ready
            readonly property string glyph: root.glyphs[index] ?? String(n)

            visible: n <= 5 || exists
            width: Math.max(30, (hasPicture ? 18 : label.implicitWidth) + 18)
            height: 28

            Chamfer {
                anchors.fill: parent
                cut: 5
                fillTop: Theme.primary
                strokeColor: Theme.crimson
                opacity: tile.focused ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: 160 } }
            }

            // A picture, if one exists (svg first, then png)
            Image {
                id: pic

                property bool triedPng: false

                visible: false
                width: 18
                height: 18
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 72
                sourceSize.height: 72
                asynchronous: true
                source: Qt.resolvedUrl("assets/workspaces/" + tile.n + ".svg")

                onStatusChanged: {
                    if (status === Image.Error && !triedPng) {
                        triedPng = true;
                        source = Qt.resolvedUrl("assets/workspaces/" + tile.n + ".png");
                    }
                }
            }

            MultiEffect {
                visible: tile.hasPicture
                anchors.centerIn: parent
                width: 18
                height: 18
                source: pic
                colorization: root.tintIcons ? 1.0 : 0.0
                colorizationColor: tile.ink
            }

            Text {
                id: label
                visible: !tile.hasPicture
                anchors.centerIn: parent
                text: tile.glyph
                color: tile.ink
                font.family: Theme.mono
                font.pixelSize: tile.glyph.length > 2 ? 13 : 17
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + tile.n + " })"])
            }
        }
    }
}
