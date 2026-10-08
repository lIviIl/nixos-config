import QtQuick
import Quickshell
import Quickshell.Io

Panel {
    id: root

    cardWidth: 880
    cardHeight: 560

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property var files: []

    function apply(path) {
        open = false;
        Quickshell.execDetached(["wallpaper", path]);
    }

    onOpenChanged: {
        if (open) {
            finder.running = true;
            grid.currentIndex = 0;
            Qt.callLater(() => grid.forceActiveFocus());
        }
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            root.open = !root.open;
        }
    }

    Process {
        id: finder
        command: ["find", root.dir, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector {
            onStreamFinished: root.files = this.text.split("\n").filter(l => l.length > 0).sort()
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        Item {
            width: parent.width
            height: 24

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "WALLPAPERS"
                color: Theme.gold
                font.family: Theme.serif
                font.pixelSize: 17
                font.letterSpacing: 3
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.files.length + " images   ENTER apply   ESC close"
                color: Theme.alpha(Theme.fg, 0.65)
                font.family: Theme.mono
                font.pixelSize: 12
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.alpha(Theme.gold, 0.7)
        }

        GridView {
            id: grid
            width: parent.width
            height: 450
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cellWidth: Math.floor(width / 3)
            cellHeight: Math.floor(cellWidth * 9 / 16) + 14
            model: root.files
            currentIndex: 0

            Keys.onEscapePressed: root.open = false
            Keys.onReturnPressed: {
                if (currentIndex >= 0 && currentIndex < root.files.length)
                    root.apply(root.files[currentIndex]);
            }
            Keys.onEnterPressed: {
                if (currentIndex >= 0 && currentIndex < root.files.length)
                    root.apply(root.files[currentIndex]);
            }

            delegate: Item {
                id: cell

                required property var modelData
                required property int index
                readonly property bool selected: index === grid.currentIndex

                width: grid.cellWidth
                height: grid.cellHeight
                z: selected ? 2 : 1

                Item {
                    anchors.fill: parent
                    anchors.margins: 8
                    scale: cell.selected ? 1.04 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.alpha(Theme.fg, 0.06)
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: root.open ? "file://" + cell.modelData : ""
                        sourceSize.width: 320
                        sourceSize.height: 180
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0

                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    // File name on the selected thumbnail
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        height: 22
                        color: Theme.alpha(Theme.bg, 0.8)
                        opacity: cell.selected ? 1 : 0

                        Behavior on opacity { NumberAnimation { duration: 140 } }

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideMiddle
                            text: cell.modelData.split("/").pop()
                            color: Theme.fg
                            font.family: Theme.mono
                            font.pixelSize: 11
                        }
                    }

                    // The active ring
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: cell.selected ? 2 : 1
                        border.color: cell.selected ? Theme.gold : Theme.alpha(Theme.fg, 0.2)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: grid.currentIndex = cell.index
                        onClicked: root.apply(cell.modelData)
                    }
                }
            }
        }
    }
}
