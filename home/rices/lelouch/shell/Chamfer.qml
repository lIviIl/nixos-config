import QtQuick
import QtQuick.Shapes

// A rectangle with its corners cut at 45 degrees, optional vertical gradient fill.
Item {
    id: root

    property real cut: 10
    property real strokeWidth: 1
    property color strokeColor: Theme.alpha(Theme.gold, 0.85)
    property color fillTop: Theme.alpha(Theme.bg, Theme.glass)
    property color fillBottom: fillTop

    Behavior on strokeColor { ColorAnimation { duration: 400 } }
    Behavior on fillTop { ColorAnimation { duration: 400 } }
    Behavior on fillBottom { ColorAnimation { duration: 400 } }

    readonly property real i: strokeWidth / 2

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeWidth: root.strokeWidth
            strokeColor: root.strokeColor
            joinStyle: ShapePath.MiterJoin

            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: 0
                y2: root.height
                GradientStop { position: 0; color: root.fillTop }
                GradientStop { position: 1; color: root.fillBottom }
            }

            startX: root.cut
            startY: root.i
            PathLine { x: root.width - root.cut; y: root.i }
            PathLine { x: root.width - root.i;   y: root.cut }
            PathLine { x: root.width - root.i;   y: root.height - root.cut }
            PathLine { x: root.width - root.cut; y: root.height - root.i }
            PathLine { x: root.cut;              y: root.height - root.i }
            PathLine { x: root.i;                y: root.height - root.cut }
            PathLine { x: root.i;                y: root.cut }
            PathLine { x: root.cut;              y: root.i }
        }
    }
}
