import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// One notification: slides in from the right with a soft rebound.
Item {
    id: toast

    required property var modelData

    // TEMPORARY: TOAST_TEST picks an experiment (plain, nolayer, fadeonly, slideonly, delay)
    readonly property string test: Quickshell.env("TOAST_TEST") || ""

    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
    readonly property bool low: modelData.urgency === NotificationUrgency.Low
    readonly property color accent: critical ? Theme.crimson : (low ? Theme.outline : Theme.gold)

    width: parent ? parent.width : 380
    height: Math.max(66, texts.implicitHeight + 28)

    Item {
        id: card
        width: parent.width
        height: parent.height
        x: toast.test === "fadeonly" ? 0 : 160
        opacity: toast.test === "slideonly" ? 1 : 0
        visible: toast.test !== "delay"

        Component.onCompleted: {
            if (toast.test === "delay")
                delayTimer.start();
            else
                enter.start();
        }

        Timer {
            id: delayTimer
            interval: 80
            onTriggered: {
                card.visible = true;
                enter.start();
            }
        }

        ParallelAnimation {
            id: enter

            NumberAnimation {
                target: card
                property: "x"
                to: 0
                duration: 400
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }

            NumberAnimation {
                target: card
                property: "opacity"
                to: 1
                duration: 140
            }
        }

        Chamfer {
            anchors.fill: parent
            visible: toast.test !== "plain"
            layered: toast.test !== "nolayer"
            cut: 8
            strokeColor: Theme.alpha(toast.accent, 0.9)
            fillTop: Theme.alpha(Theme.mix(Theme.bg, Theme.primary, 0.12), 0.95)
            fillBottom: Theme.alpha(Theme.bg, 0.95)
        }

        Rectangle {
            anchors.fill: parent
            visible: toast.test === "plain"
            color: Theme.alpha(Theme.bg, 0.95)
            border.width: 1
            border.color: Theme.alpha(toast.accent, 0.9)
        }

        // Left accent: crimson for critical, gold for normal
        Rectangle {
            x: 12
            y: 14
            width: 3
            height: parent.height - 28
            color: toast.accent
        }

        Column {
            id: texts
            x: 28
            y: 14
            width: parent.width - 28 - 16
            spacing: 4

            Text {
                width: parent.width
                text: toast.modelData.summary
                color: Theme.fg
                font.family: Theme.mono
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: toast.modelData.body
                color: Theme.alpha(Theme.fg, 0.8)
                font.family: Theme.mono
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
        }

        // Click to dismiss; hovering pauses the timeout
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: toast.modelData.dismiss()
        }

        Timer {
            interval: toast.critical ? 12000 : 6000
            running: !hover.containsMouse
            onTriggered: toast.modelData.dismiss()
        }
    }
}
