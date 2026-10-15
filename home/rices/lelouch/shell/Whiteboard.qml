import QtQuick
import QtQuick.Layouts
import Quickshell

// The whiteboard: four theme colours, three pen sizes, an eraser with its own three sizes, Undo, Export, Clear.
// The drawing itself lives in Board, so it is still here after the window closes.
ColumnLayout {
    id: board

    property string pen: "fg"
    property bool erasing: false
    property int penSize: 1
    property int eraserSize: 1

    readonly property var roles: ["fg", "gold", "crimson", "primary"]
    readonly property var penWidths: [2, 4, 8]
    readonly property var eraserWidths: [10, 22, 44]
    readonly property string exportPath: Quickshell.env("HOME") + "/Sync/notes/whiteboard.png"

    spacing: 8

    function exportImage() {
        drawArea.grabToImage(result => {
            const ok = result.saveToFile(board.exportPath);
            Quickshell.execDetached(["notify-send", "-a", "Whiteboard", ok ? "Whiteboard exported" : "Could not export the whiteboard", board.exportPath]);
        });
    }

    // Toolbar
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: board.roles

            Item {
                id: swatch

                required property string modelData
                readonly property bool selected: !board.erasing && board.pen === modelData

                Layout.preferredWidth: 30
                Layout.preferredHeight: 30

                Chamfer {
                    anchors.fill: parent
                    cut: 7
                    strokeColor: swatch.selected ? Theme.fg : Theme.alpha(Theme.gold, 0.5)
                    strokeWidth: swatch.selected ? 2 : 1
                    fillTop: "transparent"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    rotation: 45
                    color: Theme[swatch.modelData]
                }

                TapHandler {
                    onTapped: {
                        board.pen = swatch.modelData;
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

        // Sizes: the pen's, or the eraser's while erasing
        Repeater {
            model: board.erasing ? board.eraserWidths : board.penWidths

            Item {
                id: size

                required property int index
                required property int modelData
                readonly property bool selected: board.erasing ? board.eraserSize === index : board.penSize === index

                Layout.preferredWidth: 30
                Layout.preferredHeight: 30

                Chamfer {
                    anchors.fill: parent
                    cut: 7
                    strokeColor: size.selected ? Theme.fg : Theme.alpha(Theme.gold, 0.5)
                    strokeWidth: size.selected ? 2 : 1
                    fillTop: "transparent"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: board.erasing ? Math.max(6, size.modelData * 0.4) : 14
                    height: board.erasing ? width : size.modelData
                    radius: board.erasing ? 0 : size.modelData / 2
                    color: board.erasing ? "transparent" : Theme.fg
                    border.width: board.erasing ? 1.5 : 0
                    border.color: Theme.fg
                }

                TapHandler {
                    onTapped: {
                        if (board.erasing)
                            board.eraserSize = size.index;
                        else
                            board.penSize = size.index;
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
            label: "UNDO"
            enabled: Board.count > 0
            onClicked: Board.undo()
        }

        ActionButton {
            Layout.preferredHeight: 30
            label: "ERASER"
            active: board.erasing
            onClicked: board.erasing = !board.erasing
        }

        ActionButton {
            Layout.preferredHeight: 30
            label: "EXPORT"
            onClicked: board.exportImage()
        }

        ActionButton {
            Layout.preferredHeight: 30
            label: "CLEAR"
            danger: true
            needsConfirm: true
            enabled: Board.count > 0
            onClicked: Board.clear()
        }
    }

    // The drawing area
    Item {
        id: drawArea
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 200

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

            property bool full: true            // redraw every stroke on the next paint
            property var pending: []            // segments drawn since the last paint
            property real lastX: 0
            property real lastY: 0
            property string curRole: "fg"
            property real curWidth: 4
            property bool curErase: false

            function setStyle(ctx, role, width, erase) {
                ctx.globalCompositeOperation = erase ? "destination-out" : "source-over";
                ctx.strokeStyle = erase ? "rgba(0, 0, 0, 1)" : Theme[role];
                ctx.lineWidth = width;
            }

            function segment(x0, y0, x1, y1) {
                pending.push({ x0: x0, y0: y0, x1: x1, y1: y1, role: curRole, w: curWidth, erase: curErase });
                requestPaint();
            }

            onWidthChanged: {
                full = true;
                requestPaint();
            }

            onHeightChanged: {
                full = true;
                requestPaint();
            }

            Component.onCompleted: requestPaint()

            Connections {
                target: Board

                function onRevisionChanged() {
                    canvas.full = true;
                    canvas.requestPaint();
                }
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                if (full) {
                    ctx.clearRect(0, 0, width, height);
                    for (let i = 0; i < Board.strokes.length; i++) {
                        const s = Board.strokes[i];
                        setStyle(ctx, s.c, s.w, s.e);
                        ctx.beginPath();
                        ctx.moveTo(s.p[0] * width, s.p[1] * height);
                        if (s.p.length === 2)
                            ctx.lineTo(s.p[0] * width + 0.1, s.p[1] * height + 0.1);
                        for (let j = 2; j < s.p.length; j += 2)
                            ctx.lineTo(s.p[j] * width, s.p[j + 1] * height);
                        ctx.stroke();
                    }
                    full = false;
                }

                for (let k = 0; k < pending.length; k++) {
                    const g = pending[k];
                    setStyle(ctx, g.role, g.w, g.erase);
                    ctx.beginPath();
                    ctx.moveTo(g.x0, g.y0);
                    ctx.lineTo(g.x1, g.y1);
                    ctx.stroke();
                }
                pending = [];
                ctx.globalCompositeOperation = "source-over";
            }
        }

        MouseArea {
            anchors.fill: canvas
            preventStealing: true
            cursorShape: Qt.CrossCursor

            onPressed: mouse => {
                canvas.curRole = board.pen;
                canvas.curErase = board.erasing;
                canvas.curWidth = board.erasing ? board.eraserWidths[board.eraserSize] : board.penWidths[board.penSize];
                canvas.lastX = mouse.x;
                canvas.lastY = mouse.y;
                Board.begin(canvas.curRole, canvas.curWidth, canvas.curErase, mouse.x / canvas.width, mouse.y / canvas.height);
                canvas.segment(mouse.x, mouse.y, mouse.x + 0.1, mouse.y + 0.1);
            }

            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                if (Math.abs(mouse.x - canvas.lastX) + Math.abs(mouse.y - canvas.lastY) < 1)
                    return;
                Board.extend(mouse.x / canvas.width, mouse.y / canvas.height);
                canvas.segment(canvas.lastX, canvas.lastY, mouse.x, mouse.y);
                canvas.lastX = mouse.x;
                canvas.lastY = mouse.y;
            }

            onReleased: Board.end()
        }
    }
}
