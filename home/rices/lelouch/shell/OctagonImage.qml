import QtQuick

// An image clipped to a chamfered (octagon) shape, with a gold edge drawn on top.
// The octagon is a square intersected with a square turned 45 degrees, so no shader or mask is needed.
Item {
    id: root

    property url source: ""
    property real cut: 10
    property color edge: Theme.gold
    property int sourcePx: 512
    readonly property int status: image.status
    readonly property real side: Math.min(width, height)

    Item {
        id: box
        anchors.centerIn: parent
        width: root.side
        height: root.side
        clip: true

        Item {
            id: diamond
            anchors.centerIn: parent
            width: (root.side - root.cut) * Math.SQRT2
            height: width
            rotation: 45
            clip: true

            Image {
                id: image
                anchors.centerIn: parent
                width: root.side
                height: root.side
                rotation: -45
                source: root.source
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                mipmap: true
                sourceSize.width: root.sourcePx
                sourceSize.height: root.sourcePx
            }
        }
    }

    Chamfer {
        anchors.fill: parent
        cut: root.cut
        strokeWidth: 1.5
        strokeColor: root.edge
        fillTop: "transparent"
    }
}
