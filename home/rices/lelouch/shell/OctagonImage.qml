import QtQuick
import QtQuick.Effects

// An image clipped to a chamfered (octagon) shape, with a gold edge drawn on top.
Item {
    id: root

    property url source: ""
    property real cut: 10
    property color edge: Theme.gold
    property int sourcePx: 512
    readonly property int status: image.status

    Image {
        id: image
        visible: false
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        sourceSize.width: root.sourcePx
        sourceSize.height: root.sourcePx
    }

    // The octagon, used as the mask
    Item {
        id: shape
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Chamfer {
            anchors.fill: parent
            cut: root.cut
            strokeColor: "transparent"
            fillTop: "white"
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: image
        visible: image.status === Image.Ready
        maskEnabled: true
        maskSource: shape
    }

    Chamfer {
        anchors.fill: parent
        cut: root.cut
        strokeWidth: 1.5
        strokeColor: root.edge
        fillTop: "transparent"
    }
}
