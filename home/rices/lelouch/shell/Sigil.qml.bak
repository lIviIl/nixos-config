import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// A geometric Geass sigil: a ticked dial, two wings of five blades, a three-blade tail and a diamond eye.
// Characters 1-5 unfold the wing blades, 6-8 the tail, and every character lights the dial.
// flare (0..1) makes everything blaze white-hot.
Item {
    id: sigil

    property int typed: 0
    property real flare: 0
    property real px: 0
    property real py: 0
    property real size: 700

    readonly property real unit: size / 1000
    readonly property color white: "#ffffff"
    readonly property real glow: Math.max(flare, Math.min(typed, 12) / 12 * 0.8)

    // Animated progress; the overshoot makes each blade snap open mechanically
    property real wingFold: flare > 0.01 ? 5 : Math.min(typed, 5)
    property real tailFold: flare > 0.01 ? 3 : Math.max(0, Math.min(typed - 5, 3))
    property real dialTurn: typed * 6
    readonly property real dialLit: flare > 0.01 ? 24 : Math.min(typed, 12) * 2

    Behavior on wingFold {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutBack
            easing.overshoot: 1.6
        }
    }

    Behavior on tailFold {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutBack
            easing.overshoot: 1.6
        }
    }

    Behavior on dialTurn {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutBack
        }
    }

    width: size
    height: size

    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.crimson
        shadowBlur: 1.0
        shadowOpacity: 0.25 + 0.75 * sigil.glow
        autoPaddingEnabled: true
    }

    // Everything is drawn in a 1000 x 1000 space and scaled to fit
    Item {
        id: stage
        width: 1000
        height: 1000
        scale: sigil.unit
        transformOrigin: Item.TopLeft

        // ---- Dial: the deepest layer ----
        Item {
            x: -sigil.px * 12
            y: -sigil.py * 12
            width: 1000
            height: 1000

            Shape {
                ShapePath {
                    strokeWidth: 3
                    strokeColor: Theme.alpha(Theme.mix(Theme.gold, sigil.white, sigil.flare), 0.5 + 0.45 * sigil.flare)
                    fillColor: "transparent"
                    PathAngleArc { centerX: 500; centerY: 500; radiusX: 478; radiusY: 478; startAngle: 0; sweepAngle: 360 }
                }

                ShapePath {
                    strokeWidth: 1.5
                    strokeColor: Theme.alpha(Theme.gold, 0.45)
                    fillColor: "transparent"
                    PathAngleArc { centerX: 500; centerY: 500; radiusX: 446; radiusY: 446; startAngle: 0; sweepAngle: 360 }
                }

                ShapePath {
                    strokeWidth: 2
                    strokeColor: Theme.alpha(Theme.gold, 0.35)
                    strokeStyle: ShapePath.DashLine
                    dashPattern: [3, 9]
                    fillColor: "transparent"
                    PathAngleArc { centerX: 500; centerY: 500; radiusX: 392; radiusY: 392; startAngle: 0; sweepAngle: 360 }
                }
            }

            // 24 ticks; each lights as characters are typed, and the dial clicks round as it goes
            Item {
                x: 500
                y: 500
                rotation: sigil.dialTurn

                Repeater {
                    model: 24

                    Item {
                        id: tick

                        required property int index
                        readonly property bool on: index < sigil.dialLit

                        rotation: index * 15

                        Rectangle {
                            x: -2.5
                            y: -478
                            width: 5
                            height: tick.index % 6 === 0 ? 40 : 24
                            color: tick.on ? Theme.mix(Theme.crimson, sigil.white, sigil.flare) : Theme.alpha(Theme.gold, 0.35)

                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                    }
                }
            }
        }

        // ---- Tail ----
        Item {
            id: tail
            x: -sigil.px * 20
            y: -sigil.py * 20

            readonly property var spread: [90, 116, 64]
            readonly property var lengths: [280, 230, 230]

            Repeater {
                model: 3

                Feather {
                    required property int index
                    readonly property real t: Math.max(0, Math.min(1.1, sigil.tailFold - index))

                    x: 500
                    y: 520
                    rotation: 90 + (tail.spread[index] - 90) * t
                    length: tail.lengths[index]
                    halfWidth: 22
                    lit: Math.min(1, t)
                    glowWhite: sigil.flare
                }
            }
        }

        // ---- Wings ----
        Item {
            id: wings
            x: -sigil.px * 26
            y: -sigil.py * 26

            readonly property var spread: [-80, -58, -36, -14, 8]
            readonly property var lengths: [330, 365, 392, 365, 320]
            readonly property real folded: -88

            // Right wing
            Repeater {
                model: 5

                Feather {
                    required property int index
                    readonly property real t: Math.max(0, Math.min(1.1, sigil.wingFold - index))

                    x: 536
                    y: 470
                    rotation: wings.folded + (wings.spread[index] - wings.folded) * t
                    length: wings.lengths[index]
                    lit: Math.min(1, t)
                    glowWhite: sigil.flare
                }
            }

            // Left wing: the same blades mirrored
            Repeater {
                model: 5

                Feather {
                    required property int index
                    readonly property real t: Math.max(0, Math.min(1.1, sigil.wingFold - index))

                    x: 464
                    y: 470
                    rotation: 180 - (wings.folded + (wings.spread[index] - wings.folded) * t)
                    length: wings.lengths[index]
                    lit: Math.min(1, t)
                    glowWhite: sigil.flare
                }
            }
        }

        // ---- Eye: the nearest layer ----
        Item {
            id: eye
            x: -sigil.px * 40
            y: -sigil.py * 40

            readonly property real level: sigil.flare > 0.01 ? 1 : (sigil.typed > 0 ? 0.55 + 0.45 * Math.min(sigil.typed, 12) / 12 : 0.1)

            Shape {
                ShapePath {
                    strokeWidth: 4
                    strokeColor: Theme.alpha(Theme.mix(Theme.gold, sigil.white, sigil.flare), 0.9)
                    fillColor: Theme.alpha(Theme.mix(Theme.crimson, sigil.white, sigil.flare), 0.9 * eye.level)
                    joinStyle: ShapePath.MiterJoin

                    startX: 500
                    startY: 398
                    PathLine { x: 566; y: 470 }
                    PathLine { x: 500; y: 542 }
                    PathLine { x: 434; y: 470 }
                    PathLine { x: 500; y: 398 }
                }

                ShapePath {
                    strokeColor: "transparent"
                    fillColor: Theme.alpha(sigil.white, 0.9 * eye.level)
                    PathAngleArc { centerX: 500; centerY: 470; radiusX: 18; radiusY: 18; startAngle: 0; sweepAngle: 360 }
                }
            }
        }
    }
}
