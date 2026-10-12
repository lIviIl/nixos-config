import QtQuick

// A chamfered button, optionally with an icon (beside the label, or above it when vertical).
// active fills it; danger edges it in crimson;
// needsConfirm makes the first click arm it ("CONFIRM") and the second one fire.
Item {
    id: button

    property string label: ""
    property string icon: ""
    property bool vertical: false
    property bool active: false
    property bool danger: false
    property bool needsConfirm: false
    property bool armed: false

    readonly property bool hasIcon: icon !== ""
    readonly property bool hasText: label !== "" || armed
    readonly property color ink: active ? Theme.onPrimary : (danger ? Theme.crimson : Theme.fg)

    signal clicked()

    implicitWidth: hasText ? Math.ceil(content.width) + 28 : 56
    implicitHeight: vertical ? 60 : 34
    opacity: enabled ? 1 : 0.4

    // The icon is recreated when its colour or shape changes, so it is always freshly drawn
    function refreshIcon() {
        iconLoader.sourceComponent = null;
        iconLoader.sourceComponent = glyphComponent;
    }

    onInkChanged: refreshIcon()
    onIconChanged: refreshIcon()
    Component.onCompleted: refreshIcon()

    Component {
        id: glyphComponent

        Glyph {
            kind: button.icon
            tint: button.ink
        }
    }

    Chamfer {
        anchors.fill: parent
        cut: 6
        strokeColor: button.danger ? Theme.crimson : Theme.alpha(Theme.gold, area.containsMouse ? 1 : 0.6)
        fillTop: button.active ? Theme.primary : (area.containsMouse ? Theme.alpha(Theme.fg, 0.08) : "transparent")
    }

    // The icon and the label are placed by hand, so only what is visible is centred
    Item {
        id: content

        readonly property real gap: button.hasIcon && button.hasText ? (button.vertical ? 6 : 9) : 0
        readonly property real textW: button.hasText ? caption.implicitWidth : 0
        readonly property real textH: button.hasText ? caption.implicitHeight : 0

        width: button.vertical ? Math.max(button.hasIcon ? 18 : 0, textW) : (button.hasIcon ? 18 : 0) + gap + textW
        height: button.vertical ? (button.hasIcon ? 18 : 0) + gap + textH : Math.max(button.hasIcon ? 18 : 0, textH)

        // A spaced label carries one letter-space after its last letter: nudge to centre what you see
        x: Math.round((button.width - width) / 2) + (button.hasText ? 1 : 0)
        y: Math.round((button.height - height) / 2)

        Loader {
            id: iconLoader
            width: 18
            height: 18
            active: button.hasIcon
            x: button.vertical ? Math.round((content.width - 18) / 2) : 0
            y: button.vertical ? 0 : Math.round((content.height - 18) / 2)
        }

        Text {
            id: caption
            visible: button.hasText
            x: button.vertical ? Math.round((content.width - implicitWidth) / 2) : (button.hasIcon ? 18 + content.gap : 0)
            y: button.vertical ? (button.hasIcon ? 18 + content.gap : 0) : Math.round((content.height - implicitHeight) / 2)
            text: button.armed ? "CONFIRM" : button.label
            color: button.ink
            font.family: Theme.mono
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 2
        }
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: button.armed = false
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (button.needsConfirm && !button.armed) {
                button.armed = true;
                disarm.restart();
            } else {
                button.armed = false;
                button.clicked();
            }
        }
    }
}
