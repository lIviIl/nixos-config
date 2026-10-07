import QtQuick
import Quickshell
import Quickshell.Io

Panel {
    id: root

    cardWidth: 860
    cardHeight: 540

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
        anchors.margins: 20
        spacing: 12

        Text {
            text: "Wallpapers"
            color: Theme.gold
            font.family: Theme.serif
            font.pixelSize: 18
            font.letterSpacing: 2
        }

        GridView {
            id: grid
            width: parent.width
            height: 450
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cellWidth: Math.floor(width / 3)
            cellHeight: Math.floor(cellWidth * 9 / 16) + 12
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

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 10
                    color: Theme.alpha(Theme.fg, 0.06)
                    border.width: cell.selected ? 2 : 1
                    border.color: cell.selected ? Theme.gold : Theme.alpha(Theme.fg, 0.2)

                    Image {
                        anchors.fill: parent
                        anchors.margins: 3
                        source: root.open ? "file://" + cell.modelData : ""
                        sourceSize.width: 320
                        sourceSize.height: 180
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
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
