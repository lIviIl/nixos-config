import QtQuick
import Quickshell
import Quickshell.Wayland

// Success hand-off: this overlay takes over from the lock surface while the screen is solid red,
// the session unlocks underneath it, and the red fades out into the desktop.
PanelWindow {
    id: veil

    property bool open: false
    property real fade: 1

    signal finished()

    function play() {
        playAnim.restart();
    }

    visible: open
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: nothing }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Zero-size region: the whole overlay is click-through
    Item {
        id: nothing
        width: 0
        height: 0
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.crimson
        opacity: veil.fade
    }

    SequentialAnimation {
        id: playAnim

        PauseAnimation { duration: 120 }
        NumberAnimation { target: veil; property: "fade"; to: 0; duration: 650; easing.type: Easing.InOutQuad }

        ScriptAction {
            script: {
                veil.open = false;
                veil.fade = 1;
                veil.finished();
            }
        }
    }
}
