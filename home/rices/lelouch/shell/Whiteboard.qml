import QtQuick
import QtQuick.Layouts
import Quickshell

// A drawing area with four theme colours, three pen sizes, an eraser and Clear.
// It saves itself to ~/Sync/notes/whiteboard.png and reloads from it.
ColumnLayout {
    id: board

    property color pen: Theme.fg
    property real penWidth: 3
    property bool erasing: false
    property bool dirty: false

    readonly property string dir: Quickshell.env("HOME") + "/Sync/notes"
    readonly property string path: dir + "/whiteboard.png"
    readonly property string fileUrl: "file://" + path

    Layout.fillWidth: true
    spacing: 8

    function save() {
        if (!dirty)
            return;
        dirty = false;
        canvas.save(path);
    }

    function clear() {
        canvas.clear();
        dirty = true;
        saveTimer.restart();
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", board.dir])
    Component.onDestruction: board.save()

    Timer {
        id: saveTimer
        interval: 1200
        onTriggered: board.save()
    }

    // The canvas is loaded from disk shortly after it has its final size
    Timer {
        interval: 150
        running: true
        onTriggered: canvas.loadImage(board.fileUrl)
    }

    // Toolbar
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: [Theme.fg, Theme.gold, Theme.crimson, Theme.primary]

            Item {
                required property color modelData

                Layout.preferredWidth: 30
                Layout.preferredHeight: 30

                Chamfer {
                    anchors.fill: parent
                    cut: 7
                    strokeColor: !board.erasing && Qt.colorEqual(board.pen, parent.modelData) ? Theme.fg : Theme.alpha(Theme.gold, 0.5)
                    strokeWidth: !board.erasing && Qt.colorEqual(board.pen, parent.modelData) ? 2 : 1
                    fillTop: "transparent"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    rotation: 45
                    color: parent.modelData
                }

                TapHandler {
                    onTapped: {
                        board.pen = parent.modelData;
                        board.erasing = false;
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 20
            color: Theme.alpha(Theme.gold, 0.45)
        }

        Repeater {
            model: [2, 4, 8]

            Item {
                required property real modelData

                Layout.preferredWidth: 30
                Layout.preferredHeight: 30

                Chamfer {
                    anchors.fill: parent
                    cut: 7
                    strokeColor: !board.erasing && board.penWidth === parent.modelData ? Theme.fg : Theme.alpha(Theme.gold, 0.5)
                    strokeWidth: !board.erasing && board.penWidth === parent.modelData ? 2 : 1
                    fillTop: "transparent"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: parent.modelData
                    radius: parent.modelData / 2
                    color: Theme.fg
                }

                TapHandler {
                    onTapped: {
                        board.penWidth = parent.modelData;
                        board.erasing = false;
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        ActionButton {
            Layout.preferredHeight: 30
            label: "ERASER"
            active: board.erasing
            onClicked: board.erasing = !board.erasing
        }

        ActionButton {
            Layout.preferredHeight: 30
            label: "CLEAR"
            danger: true
            needsConfirm: true
            onClicked: board.clear()
        }
    }

    // The drawing area
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 280

        Chamfer {
            anchors.fill: parent
            cut: 8
            strokeColor: Theme.alpha(Theme.gold, 0.6)
            fillTop: Theme.alpha(Theme.bg, 0.5)
        }

        Canvas {
            id: canvas
            anchors.fill: parent
            anchors.margins: 6

            property var segments: []
            property bool restore: false
            property real lastX: 0
            property real lastY: 0

            function addSegment(x0, y0, x1, y1) {
                segments.push({
                    x0: x0,
                    y0: y0,
                    x1: x1,
                    y1: y1,
                    color: board.pen,
                    width: board.erasing ? 18 : board.penWidth,
                    erase: board.erasing
                });
                requestPaint();
            }

            function clear() {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                segments = [];
                requestPaint();
            }

            onImageLoaded: {
                restore = true;
                requestPaint();
            }

            onPaint: {
                const ctx = getContext("2d");

                if (restore && isImageLoaded(board.fileUrl)) {
                    ctx.drawImage(board.fileUrl, 0, 0);
                    restore = false;
                }

                for (let i = 0; i < segments.length; i++) {
                    const s = segments[i];
                    ctx.globalCompositeOperation = s.erase ? "destination-out" : "source-over";
                    ctx.strokeStyle = s.erase ? "rgba(0, 0, 0, 1)" : s.color;
                    ctx.lineWidth = s.width;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(s.x0, s.y0);
                    ctx.lineTo(s.x1, s.y1);
                    ctx.stroke();
                }

                ctx.globalCompositeOperation = "source-over";
                segments = [];
            }
        }

        MouseArea {
            anchors.fill: canvas
            preventStealing: true
            cursorShape: Qt.CrossCursor

            onPressed: mouse => {
                canvas.lastX = mouse.x;
                canvas.lastY = mouse.y;
                canvas.addSegment(mouse.x, mouse.y, mouse.x + 0.1, mouse.y + 0.1);
                board.dirty = true;
            }

            onPositionChanged: mouse => {
                if (pressed) {
                    canvas.addSegment(canvas.lastX, canvas.lastY, mouse.x, mouse.y);
                    canvas.lastX = mouse.x;
                    canvas.lastY = mouse.y;
                }
            }

            onReleased: saveTimer.restart()
        }
    }
}
