import QtQuick
import QtQuick.Shapes

// The circle behind the emblem: a fixed ring, a dashed ring and a ring of ticks,
// the last two turning slowly in opposite directions.
Item {
    id: dial

    property real size: 700
    property real flare: 0
    readonly property color white: "#ffffff"
    readonly property color line: Theme.mix(Theme.gold, white, flare)

    width: size
    height: size

    Shape {
        ShapePath {
            strokeWidth: 2
            strokeColor: Theme.alpha(dial.line, 0.5 + 0.4 * dial.flare)
            fillColor: "transparent"
            PathAngleArc { centerX: dial.size / 2; centerY: dial.size / 2; radiusX: dial.size * 0.47; radiusY: dial.size * 0.47; startAngle: 0; sweepAngle: 360 }
        }
    }

    Item {
        anchors.fill: parent

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 120000
            loops: Animation.Infinite
        }

        Shape {
            ShapePath {
                strokeWidth: 1.5
                strokeColor: Theme.alpha(dial.line, 0.4 + 0.4 * dial.flare)
                strokeStyle: ShapePath.DashLine
                dashPattern: [3, 9]
                fillColor: "transparent"
                PathAngleArc { centerX: dial.size / 2; centerY: dial.size / 2; radiusX: dial.size * 0.43; radiusY: dial.size * 0.43; startAngle: 0; sweepAngle: 360 }
            }
        }
    }

    Item {
        anchors.fill: parent

        RotationAnimator on rotation {
            from: 360
            to: 0
            duration: 180000
            loops: Animation.Infinite
        }

        Shape {
            ShapePath {
                strokeWidth: 10
                strokeColor: Theme.alpha(dial.line, 0.3 + 0.4 * dial.flare)
                strokeStyle: ShapePath.DashLine
                dashPattern: [0.12, 3.2]
                fillColor: "transparent"
                PathAngleArc { centerX: dial.size / 2; centerY: dial.size / 2; radiusX: dial.size * 0.455; radiusY: dial.size * 0.455; startAngle: 0; sweepAngle: 360 }
            }
        }
    }
}
