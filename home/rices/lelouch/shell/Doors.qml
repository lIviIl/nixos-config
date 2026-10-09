import QtQuick
import Quickshell
import Quickshell.Wayland

// After authorization this overlay takes over from the lock surface (the screen is white at that
// instant), the session unlocks underneath it, then the two halves retract like blast doors.
PanelWindow {
    id: doors

    property bool open: false
    property real split: 0     // 0 = closed, 1 = fully retracted
    property real veil: 1      // white handoff flash

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

    SequentialAnimation {
        id: playAnim

        NumberAnimation { target: doors; property: "veil"; to: 0; duration: 200 }
        PauseAnimation { duration: 140 }
        NumberAnimation { target: doors; property: "split"; to: 1; duration: 950; easing.type: Easing.InOutCubic }

        ScriptAction {
            script: {
                doors.open = false;
                doors.split = 0;
                doors.veil = 1;
                doors.finished();
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: doors.open

        sourceComponent: Item {
            id: stage

            // Left door
            Item {
                width: stage.width / 2
                height: stage.height
                x: -doors.split * width
                clip: true

                LockScene {
                    width: stage.width
                    height: stage.height
                    holdBlaze: true
                }

                Rectangle {
                    anchors.right: parent.right
                    width: 5
                    height: parent.height
                    color: Theme.gold
                }
            }

            // Right door
            Item {
                width: stage.width / 2
                height: stage.height
                x: stage.width / 2 + doors.split * width
                clip: true

                LockScene {
                    x: -stage.width / 2
                    width: stage.width
                    height: stage.height
                    holdBlaze: true
                }

                Rectangle {
                    anchors.left: parent.left
                    width: 5
                    height: parent.height
                    color: Theme.gold
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "white"
                opacity: doors.veil
            }
        }
    }
}
