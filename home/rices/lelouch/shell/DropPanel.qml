import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A panel that drops down from the bar, centred under the icon that opened it (see Ui.anchorTo).
// Its window is exactly as big as its card, stays mapped for good, and shrinks to one transparent pixel while closed
// (unmapping layer surfaces made clicks on the bar unreliable). There is no click mask and no invisible full-screen
// area, so the desktop and the bar stay fully usable around it.
// Close it with Esc (after clicking the panel) or its bar button. The page is loaded only while the panel is shown.
PanelWindow {
    id: win

    property string name: ""                    // matches Ui.popup
    property string place: "center"             // where a shortcut (no icon) opens it: left, center or right
    property int cardWidth: 460
    property Component page: null

    readonly property bool open: Ui.popup === name
    readonly property bool shown: open || card.opacity > 0.01
    readonly property int padTop: 20
    readonly property int padBottom: 22
    readonly property int padSide: 20
    readonly property real screenW: screen ? screen.width : 1920
    readonly property real maxCard: (screen ? screen.height : 1080) - 56 - 12
    readonly property real wanted: padTop + padBottom + (loader.item ? loader.item.implicitHeight : 120)
    readonly property real finalHeight: Math.min(wanted, maxCard)
    readonly property real homeX: place === "left" ? 12 + cardWidth / 2 : (place === "right" ? screenW - 12 - cardWidth / 2 : screenW / 2)

    // Where the card sits: centred under the icon, kept 12 px inside the screen
    property real cardLeft: 12

    function latch() {
        const want = Ui.anchorX >= 0 ? Ui.anchorX : homeX;
        cardLeft = Math.max(12, Math.min(screenW - cardWidth - 12, want - cardWidth / 2));
    }

    onOpenChanged: {
        if (open)
            latch();
    }

    Component.onCompleted: latch()

    // Another icon asked for this panel while it was already open: move it there
    Connections {
        target: Ui

        function onAnchorXChanged() {
            if (win.open)
                win.latch();
        }
    }

    // Tell notifications where the open panel is
    Binding {
        target: Ui
        property: "surfaceLeft"
        value: win.cardLeft
        when: win.open
    }

    Binding {
        target: Ui
        property: "surfaceRight"
        value: win.cardLeft + win.cardWidth
        when: win.open
    }

    // The window is as tall as the card will be: it grows at once, and shrinks after the card's own animation
    property real winHeight: 160

    onFinalHeightChanged: {
        if (finalHeight > winHeight)
            winHeight = finalHeight;
        else
            shrink.restart();
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: shown ? cardWidth : 1
    implicitHeight: shown ? winHeight : 1

    anchors {
        top: true
        left: true
    }

    margins {
        top: 56
        left: win.cardLeft
    }

    // Typing works once the panel is clicked; the setting never changes while the window exists
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    IpcHandler {
        target: win.name

        function toggle(): void {
            Ui.anchorTo();
            Ui.togglePopup(win.name);
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: win.open
        onActivated: Ui.popup = ""
    }

    Timer {
        id: shrink
        interval: 320
        onTriggered: win.winHeight = win.finalHeight
    }

    Item {
        id: card
        width: win.cardWidth
        height: win.finalHeight
        y: win.open ? 0 : -24
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
            x: win.padSide
            y: win.padTop
            width: parent.width - 2 * win.padSide
            height: parent.height - win.padTop - win.padBottom
            clip: true

            Loader {
                id: loader
                width: parent.width
                height: item ? Math.min(item.implicitHeight, win.maxCard - win.padTop - win.padBottom) : 120
                active: win.shown
                sourceComponent: win.page
            }
        }
    }
}
