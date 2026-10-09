import QtQuick
import QtQuick.Shapes

// One blade of a wing. Drawn pointing along +x from its pivot; rotate the item to aim it.
Item {
    id: feather

    property real length: 340
    property real halfWidth: 26
    property real lit: 0           // 0..1
    property real glowWhite: 0     // 0..1, the success flare
    readonly property color white: "#ffffff"

    Shape {
        ShapePath {
            strokeWidth: 3
            strokeColor: Theme.alpha(Theme.mix(Theme.gold, feather.white, feather.glowWhite), 0.35 + 0.65 * feather.lit)
            fillColor: Theme.alpha(Theme.mix(Theme.crimson, feather.white, feather.glowWhite), 0.88 * feather.lit)
            joinStyle: ShapePath.MiterJoin

            startX: 0
            startY: -feather.halfWidth * 0.35
            PathLine { x: feather.length * 0.22; y: -feather.halfWidth }
            PathLine { x: feather.length; y: 0 }
            PathLine { x: feather.length * 0.22; y: feather.halfWidth }
            PathLine { x: 0; y: feather.halfWidth * 0.35 }
            PathLine { x: 0; y: -feather.halfWidth * 0.35 }
        }

        // Spine
        ShapePath {
            strokeWidth: 2
            strokeColor: Theme.alpha(Theme.mix(Theme.gold, feather.white, feather.glowWhite), 0.25 + 0.55 * feather.lit)
            fillColor: "transparent"

            startX: feather.length * 0.08
            startY: 0
            PathLine { x: feather.length * 0.92; y: 0 }
        }
    }
}
