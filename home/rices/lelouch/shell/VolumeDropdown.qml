import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Slides down from the bar (150 ms). Closes shortly after the pointer leaves it.
PanelWindow {
    id: win

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    function setVolume(v) {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)]);
    }

    PwObjectTracker {
        objects: [win.sink]
    }

    visible: Ui.volumeOpen || card.y > -card.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    margins {
        top: 54
        right: 12
    }

    implicitWidth: 300
    implicitHeight: 110

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: card
            width: parent.width
            height: parent.height
            y: Ui.volumeOpen ? 0 : -height
            opacity: Ui.volumeOpen ? 1 : 0

            Behavior on y {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity { NumberAnimation { duration: 150 } }

            Chamfer {
                anchors.fill: parent
                cut: 10
                strokeColor: Theme.alpha(Theme.gold, 0.9)
                fillTop: Theme.alpha(Theme.mix(Theme.bg, Theme.primary, 0.15), 0.95)
                fillBottom: Theme.alpha(Theme.bg, 0.95)
            }

            HoverHandler {
                id: hover
            }

            Timer {
                interval: 1400
                running: Ui.volumeOpen && !hover.hovered
                onTriggered: Ui.volumeOpen = false
            }

            Item {
                anchors.fill: parent
                anchors.margins: 18

                Text {
                    id: heading
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "VOLUME   " + Math.round((slider.preview >= 0 ? slider.preview : win.volume) * 100) + "%"
                    color: Theme.gold
                    font.family: Theme.serif
                    font.pixelSize: 15
                    font.letterSpacing: 2
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: win.muted ? "UNMUTE" : "MUTE"
                    color: win.muted ? Theme.crimson : Theme.alpha(Theme.fg, 0.8)
                    font.family: Theme.mono
                    font.pixelSize: 12
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                    }
                }

                // Slider: the volume is applied while dragging
                MouseArea {
                    id: slider
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 30

                    property real preview: -1
                    property real applied: -1

                    function valueAt(x) {
                        return Math.max(0, Math.min(1, x / width));
                    }

                    function push() {
                        if (preview >= 0 && preview !== applied) {
                            applied = preview;
                            win.setVolume(preview);
                        }
                    }

                    onPressed: mouse => {
                        settle.stop();
                        preview = valueAt(mouse.x);
                        push();
                    }

                    onPositionChanged: mouse => {
                        if (pressed)
                            preview = valueAt(mouse.x);
                    }

                    onReleased: {
                        push();
                        settle.restart();
                    }

                    // Sends the dragged value while the mouse is held down
                    Timer {
                        interval: 60
                        repeat: true
                        running: slider.pressed
                        onTriggered: slider.push()
                    }

                    // After release, keep showing the chosen value until the system volume has caught up
                    Timer {
                        id: settle
                        interval: 500
                        onTriggered: {
                            slider.preview = -1;
                            slider.applied = -1;
                        }
                    }

                    Rectangle {
                        id: track
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        color: Theme.alpha(Theme.fg, 0.2)

                        Rectangle {
                            height: parent.height
                            width: parent.width * (slider.preview >= 0 ? slider.preview : win.volume)
                            color: win.muted ? Theme.alpha(Theme.fg, 0.4) : Theme.primary
                        }
                    }

                    // Diamond handle
                    Rectangle {
                        width: 10
                        height: 10
                        rotation: 45
                        color: Theme.gold
                        anchors.verticalCenter: parent.verticalCenter
                        x: track.width * (slider.preview >= 0 ? slider.preview : win.volume) - width / 2
                    }
                }
            }
        }
    }
}
