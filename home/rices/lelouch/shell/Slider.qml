import QtQuick

// A flat slider with a diamond handle. Drag or click; moved(v) fires while dragging (about 16 times a second).
Item {
    id: slider

    property real value: 0              // 0..1
    property color fill: Theme.primary
    property real preview: -1
    property real applied: -1
    readonly property real shown: preview >= 0 ? preview : value

    signal moved(real v)

    implicitHeight: 28

    function fraction(x) {
        return Math.max(0, Math.min(1, (x - 6) / (width - 12)));
    }

    function push() {
        if (preview >= 0 && preview !== applied) {
            applied = preview;
            moved(preview);
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent

        onPressed: mouse => {
            settle.stop();
            slider.preview = slider.fraction(mouse.x);
            slider.push();
        }

        onPositionChanged: mouse => {
            if (pressed)
                slider.preview = slider.fraction(mouse.x);
        }

        onReleased: {
            slider.push();
            settle.restart();
        }
    }

    // Sends the dragged value while the mouse is held down
    Timer {
        interval: 60
        repeat: true
        running: area.pressed
        onTriggered: slider.push()
    }

    // After release, keep showing the chosen value until the system has caught up
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
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        height: 4
        color: Theme.alpha(Theme.fg, 0.2)

        Rectangle {
            height: parent.height
            width: parent.width * slider.shown
            color: slider.fill
        }
    }

    Rectangle {
        width: 10
        height: 10
        rotation: 45
        color: Theme.gold
        anchors.verticalCenter: parent.verticalCenter
        x: 6 + track.width * slider.shown - width / 2
    }
}
