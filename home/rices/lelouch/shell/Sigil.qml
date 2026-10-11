import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// The Geass emblem. It ignites in three steps (one per character of a three-letter password),
// pulses on every key, and blazes white-hot when flare goes to 1.
// The circle around it is Dial.qml.
Item {
    id: sigil

    property int typed: 0
    property real flare: 0
    property real px: 0
    property real py: 0
    property real size: 700

    // Optional: your own SVG of the emblem (a single-colour shape in the shell folder).
    // Empty uses the drawn emblem below.
    property url artwork: ""

    readonly property color white: "#ffffff"
    readonly property real k: size * 0.86 / 600     // the emblem is drawn in a 600 x 380 box

    // Ignition steps. Change both 3s if your password is longer.
    property real lit: flare > 0.01 ? 1 : Math.min(typed, 3) / 3
    property real pulse: 0
    readonly property real glow: Math.min(1, 0.18 + 0.5 * lit + 0.25 * pulse + 0.5 * flare)

    Behavior on lit {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    onTypedChanged: {
        if (typed > 0)
            pulseAnim.restart();
    }

    SequentialAnimation {
        id: pulseAnim

        NumberAnimation { target: sigil; property: "pulse"; to: 1; duration: 50 }
        NumberAnimation { target: sigil; property: "pulse"; to: 0; duration: 220; easing.type: Easing.OutQuad }
    }

    width: size
    height: size

    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.crimson
        shadowBlur: 1.0
        shadowOpacity: sigil.glow
        autoPaddingEnabled: true
    }

    Item {
        id: emblem
        visible: sigil.artwork.toString() === ""
        width: 600
        height: 380
        scale: sigil.k
        transformOrigin: Item.TopLeft
        x: (sigil.size - 600 * sigil.k) / 2 - sigil.px * 0.012 * sigil.size
        y: (sigil.size - 380 * sigil.k) / 2 - sigil.py * 0.012 * sigil.size

        Shape {
            ShapePath {
                strokeWidth: 3
                strokeColor: Theme.alpha(Theme.mix(Theme.gold, sigil.white, sigil.flare), 0.55 + 0.4 * sigil.lit)
                fillColor: Theme.alpha(Theme.mix(Theme.crimson, sigil.white, sigil.flare), 0.1 + 0.82 * sigil.lit)
                joinStyle: ShapePath.RoundJoin

                startX: 0
                startY: 0
                PathCubic { control1X: 40;  control1Y: 62;  control2X: 150; control2Y: 112; x: 258; y: 177 }
                PathCubic { control1X: 263; control1Y: 179; control2X: 266; control2Y: 185; x: 264; y: 192 }

                PathLine { x: 251; y: 250 }
                PathCubic { control1X: 248; control1Y: 262; control2X: 254; control2Y: 270; x: 264; y: 277 }
                PathLine { x: 300; y: 291 }

                PathLine { x: 336; y: 277 }
                PathCubic { control1X: 346; control1Y: 270; control2X: 352; control2Y: 262; x: 349; y: 250 }
                PathLine { x: 336; y: 192 }
                PathCubic { control1X: 334; control1Y: 185; control2X: 337; control2Y: 179; x: 342; y: 177 }
                PathCubic { control1X: 450; control1Y: 112; control2X: 560; control2Y: 62;  x: 600; y: 0 }

                PathCubic { control1X: 575; control1Y: 85; control2X: 480; control2Y: 160; x: 395; y: 213 }
                PathLine { x: 402; y: 292 }
                PathLine { x: 300; y: 378 }

                PathLine { x: 198; y: 292 }
                PathLine { x: 205; y: 213 }
                PathCubic { control1X: 120; control1Y: 160; control2X: 25; control2Y: 85; x: 0; y: 0 }
            }
        }
    }

    Image {
        id: artImage
        visible: false
        source: sigil.artwork
        sourceSize.width: 1600
        fillMode: Image.PreserveAspectFit
        width: sigil.size * 0.86
        height: sigil.size * 0.86
    }

    MultiEffect {
        visible: sigil.artwork.toString() !== ""
        source: artImage
        width: artImage.width
        height: artImage.height
        x: (sigil.size - width) / 2 - sigil.px * 0.012 * sigil.size
        y: (sigil.size - height) / 2 - sigil.py * 0.012 * sigil.size
        colorization: 1.0
        colorizationColor: Theme.alpha(Theme.mix(Theme.crimson, sigil.white, sigil.flare), 0.12 + 0.86 * sigil.lit)
    }
}
