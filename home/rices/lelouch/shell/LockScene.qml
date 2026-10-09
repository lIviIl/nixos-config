import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

// The whole lock composition. The lock surface and the doors overlay both draw this.
Item {
    id: scene


    readonly property real u: height / 1080
    readonly property int typed: LockState.typed

    // Cursor parallax, smoothed
    property real px: LockState.px
    property real py: LockState.py

    Behavior on px { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    Behavior on py { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    // Driven by events
    property real shakeX: 0
    property real shakeY: 0
    property real ab: 0              // chromatic aberration amount
    property real failFlash: 0
    property real blaze: 0           // success flare
    property var strips: []          // glitch slices

    readonly property real whiteOut: Math.max(0, (blaze - 0.35) / 0.65)


    // The current wallpaper, as recorded by the `wallpaper` command
    FileView {
        id: wallFile
        path: Quickshell.env("HOME") + "/.cache/current-wallpaper"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    readonly property string wallpaper: {
        try {
            const p = wallFile.text().trim();
            return p !== "" ? "file://" + p : "";
        } catch (e) {
            return "";
        }
    }

    // ---- Rejection: elastic shake, chromatic split, harsh flicker ----
    ParallelAnimation {
        id: rejectAnim

        SequentialAnimation {
            NumberAnimation { target: scene; property: "shakeX"; to: -scene.width * 0.028; duration: 55; easing.type: Easing.OutQuad }
            NumberAnimation { target: scene; property: "shakeX"; to: 0; duration: 650; easing.type: Easing.OutElastic; easing.amplitude: 1.1; easing.period: 0.3 }
        }

        SequentialAnimation {
            NumberAnimation { target: scene; property: "shakeY"; to: scene.height * 0.012; duration: 55; easing.type: Easing.OutQuad }
            NumberAnimation { target: scene; property: "shakeY"; to: 0; duration: 650; easing.type: Easing.OutElastic; easing.amplitude: 1.1; easing.period: 0.3 }
        }

        SequentialAnimation {
            NumberAnimation { target: scene; property: "ab"; to: 1; duration: 40 }
            PauseAnimation { duration: 260 }
            NumberAnimation { target: scene; property: "ab"; to: 0; duration: 420; easing.type: Easing.OutQuad }
        }

        SequentialAnimation {
            NumberAnimation { target: scene; property: "failFlash"; to: 0.55; duration: 35 }
            NumberAnimation { target: scene; property: "failFlash"; to: 0; duration: 90 }
            PauseAnimation { duration: 50 }
            NumberAnimation { target: scene; property: "failFlash"; to: 0.35; duration: 30 }
            NumberAnimation { target: scene; property: "failFlash"; to: 0; duration: 220 }
        }
    }

    // ---- Success: the sigil flares ----
    NumberAnimation {
        id: blazeAnim
        target: scene
        property: "blaze"
        to: 1
        duration: 520
        easing.type: Easing.InCubic
    }

    Connections {
        target: LockState

        function onFailPulseChanged() {
            rejectAnim.restart();
        }

        function onGrantedChanged() {
            if (LockState.granted)
                blazeAnim.restart();
        }
    }

    // New random glitch slices every few frames while the aberration is active
    Timer {
        interval: 45
        repeat: true
        running: scene.ab > 0
        onTriggered: {
            const list = [];
            for (let i = 0; i < 7; i++) {
                const h = (0.02 + Math.random() * 0.07) * scene.height;
                list.push({
                    y: Math.random() * (scene.height - h),
                    h: h,
                    dx: (Math.random() - 0.5) * scene.width * 0.1
                });
            }
            scene.strips = list;
        }
        onRunningChanged: {
            if (!running)
                scene.strips = [];
        }
    }

    Item {
        id: shaker
        width: scene.width
        height: scene.height
        x: scene.shakeX
        y: scene.shakeY

        Item {
            id: content
            anchors.fill: parent
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                color: "#07050d"
            }

            Image {
                id: art
                visible: false
                width: content.width
                height: content.height
                source: scene.wallpaper
                fillMode: Image.PreserveAspectCrop
            }

            // Plane 1, farthest: heavily blurred and dark; moves least
            MultiEffect {
                visible: art.status === Image.Ready
                source: art
                width: content.width * 1.14
                height: content.height * 1.14
                x: (content.width - width) / 2 - scene.px * 16 * scene.u
                y: (content.height - height) / 2 - scene.py * 16 * scene.u
                blurEnabled: true
                blur: 1.0
                blurMax: 48
                brightness: -0.5
            }

            // Plane 2: the art itself, dimmed; moves more
            MultiEffect {
                visible: art.status === Image.Ready
                source: art
                width: content.width * 1.07
                height: content.height * 1.07
                x: (content.width - width) / 2 - scene.px * 34 * scene.u
                y: (content.height - height) / 2 - scene.py * 34 * scene.u
                brightness: -0.28
                opacity: 0.78
            }

            // Palette tint
            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.bg, 0.3)
            }

            // Vignette
            Shape {
                anchors.fill: parent

                ShapePath {
                    strokeColor: "transparent"

                    fillGradient: RadialGradient {
                        centerX: content.width / 2
                        centerY: content.height / 2
                        centerRadius: Math.max(content.width, content.height) * 0.62
                        focalX: centerX
                        focalY: centerY
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
                        GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, 0.35) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                    }

                    startX: 0
                    startY: 0
                    PathLine { x: content.width; y: 0 }
                    PathLine { x: content.width; y: content.height }
                    PathLine { x: 0; y: content.height }
                    PathLine { x: 0; y: 0 }
                }
            }

            // Plane 3: the sigil, with its own layers inside and a slight 3D tilt
            Sigil {
                id: sigil
                size: Math.min(content.width, content.height) * 0.92
                x: (content.width - width) / 2 - scene.px * 30 * scene.u
                y: content.height * 0.58 - height / 2 - scene.py * 30 * scene.u
                typed: scene.typed
                flare: scene.blaze
                px: scene.px
                py: scene.py
                scale: 1 + 30 * scene.blaze

                transform: Rotation {
                    origin.x: sigil.width / 2
                    origin.y: sigil.height / 2
                    axis.x: 0
                    axis.y: 1
                    axis.z: 0
                    angle: scene.px * 7
                }
            }

            // Status line under the sigil
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -scene.px * 22 * scene.u
                y: content.height * 0.925 - scene.py * 22 * scene.u
                text: LockState.status
                color: LockState.status === "COMMAND REJECTED" ? Theme.crimson : Theme.gold
                font.family: Theme.mono
                font.pixelSize: Math.round(16 * scene.u + 2)
                font.bold: true
                font.letterSpacing: 7
            }

            // Plane 4, nearest: the time. Moves most.
            Item {
                id: clockPlane
                width: content.width
                height: content.height * 0.4
                x: -scene.px * 46 * scene.u
                y: content.height * 0.05 - scene.py * 46 * scene.u

                transform: Rotation {
                    origin.x: clockPlane.width / 2
                    origin.y: clockPlane.height / 2
                    axis.x: 0
                    axis.y: 1
                    axis.z: 0
                    angle: scene.px * 5
                }

                Text {
                    id: caption
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "AUTHORIZATION REQUIRED"
                    color: Theme.gold
                    font.family: Theme.mono
                    font.pixelSize: Math.round(14 * scene.u + 2)
                    font.bold: true
                    font.letterSpacing: 9
                }

                Item {
                    id: timeBox
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: caption.bottom
                    anchors.topMargin: scene.height * 0.012
                    width: hhmm.implicitWidth + 18 + secs.implicitWidth
                    height: hhmm.implicitHeight

                    Text {
                        id: hhmm
                        text: Qt.formatDateTime(LockState.now, "HH:mm")
                        color: Theme.fg
                        font.family: Theme.serif
                        font.weight: Font.Light
                        font.pixelSize: Math.round(scene.height * 0.2)
                        font.letterSpacing: Math.round(scene.height * 0.006)
                    }

                    // Seconds, like the last digits of a countdown
                    Text {
                        id: secs
                        x: hhmm.width + 18
                        anchors.baseline: hhmm.baseline
                        text: Qt.formatDateTime(LockState.now, "ss")
                        color: Theme.gold
                        font.family: Theme.serif
                        font.pixelSize: Math.round(scene.height * 0.075)
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: timeBox.bottom
                    anchors.topMargin: scene.height * 0.004
                    text: Qt.formatDateTime(LockState.now, "dddd  ·  dd MMMM yyyy").toUpperCase()
                    color: Theme.alpha(Theme.fg, 0.85)
                    font.family: Theme.serif
                    font.pixelSize: Math.round(scene.height * 0.026)
                    font.letterSpacing: Math.round(scene.height * 0.009)
                }
            }
        }

        // Chromatic aberration: tinted copies of everything, split apart
        MultiEffect {
            visible: scene.ab > 0
            source: content
            width: content.width
            height: content.height
            x: -scene.ab * 24 * scene.u
            opacity: scene.ab * 0.6
            colorization: 1.0
            colorizationColor: "#ff1030"
        }

        MultiEffect {
            visible: scene.ab > 0
            source: content
            width: content.width
            height: content.height
            x: scene.ab * 24 * scene.u
            opacity: scene.ab * 0.6
            colorization: 1.0
            colorizationColor: "#00e0ff"
        }

        // Glitch: horizontal slices of the screen thrown sideways
        Repeater {
            model: scene.strips

            ShaderEffectSource {
                required property var modelData

                sourceItem: content
                sourceRect: Qt.rect(0, modelData.y, content.width, modelData.h)
                x: modelData.dx * scene.ab
                y: modelData.y
                width: content.width
                height: modelData.h
            }
        }
    }

    // Harsh flicker on rejection
    Rectangle {
        anchors.fill: parent
        color: Theme.crimson
        opacity: scene.failFlash
    }

    // White-hot peak of the flare on success
    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: scene.whiteOut
    }
}
