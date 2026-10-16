import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A panel that drops down from the bar. Its window starts just below the bar and covers the rest of the screen
// invisibly, but it takes input only inside its card, so the desktop (and the bar) stay usable while it is open.
// Close it with Esc, the CLOSE label, or its bar button. The page inside is loaded only while the panel is on
// screen, and the card is exactly as tall as the page wants (up to the screen).
PanelWindow {
    id: win

    property string name: ""                    // matches Ui.popup
    property string place: "center"             // left, center or right
    property int cardWidth: 460
    property Component page: null

    readonly property bool open: Ui.popup === name
    readonly property int padTop: 20
    readonly property int padBottom: 22
    readonly property int padSide: 20
    readonly property real maxCard: Math.max(200, height - 4 - 12)
    readonly property real wanted: padTop + padBottom + (loader.item ? loader.item.implicitHeight : 120)
    readonly property real finalHeight: Math.min(wanted, maxCard)
    readonly property real cardX: place === "left" ? 12 : (place === "right" ? width - cardWidth - 12 : Math.round((width - cardWidth) / 2))

    visible: open || card.opacity > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    margins.top: 52

    // Input only where the card will be
    mask: Region { item: hitbox }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Typing works once the panel is clicked; it never grabs the keyboard on its own
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    IpcHandler {
        target: win.name

        function toggle(): void {
            Ui.togglePopup(win.name);
        }
    }

    Item {
        id: hitbox
        x: win.cardX
        y: 4
        width: win.cardWidth
        height: win.finalHeight
    }

    Item {
        id: card
        width: win.cardWidth
        height: win.finalHeight
        x: win.cardX
        y: 4 + (win.open ? 0 : -24)
        opacity: win.open ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        CardFrame {
            anchors.fill: parent
        }

        Item {
            focus: true
            Keys.onEscapePressed: Ui.popup = ""
        }

        Item {
            x: win.padSide
            y: win.padTop
            width: parent.width - 2 * win.padSide
            height: parent.height - win.padTop - win.padBottom
            clip: true

            Loader {
                id: loader
                width: parent.width
                height: item ? Math.min(item.implicitHeight, win.maxCard - win.padTop - win.padBottom) : 120
                active: win.visible
                sourceComponent: win.page
            }
        }

        Text {
            x: parent.width - width - 26
            y: 4
            text: "CLOSE"
            color: Theme.alpha(Theme.fg, 0.6)
            font.family: Theme.mono
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 2

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: Ui.popup = ""
            }
        }
    }
}
