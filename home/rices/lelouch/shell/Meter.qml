import QtQuick

// A flat horizontal gauge; turns crimson when nearly full.
Item {
    id: meter

    property real value: 0         // 0..1
    property color fill: Theme.primary
    readonly property bool warn: value > 0.85

    implicitHeight: 8
    implicitWidth: 100

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.fg, 0.14)
    }

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, meter.value))
        height: parent.height
        color: meter.warn ? Theme.crimson : meter.fill

        Behavior on width {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }
}
