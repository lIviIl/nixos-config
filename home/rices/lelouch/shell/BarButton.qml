import QtQuick

// An icon-only button for the bar, with an optional marker for unread items and an active state.
// It uses a plain press/release area with no hover tracking: hover handlers made bar clicks unreliable.
Item {
    id: button

    property string icon: ""
    property bool active: false
    property int badge: 0

    signal clicked()
    signal rightClicked()

    width: 28
    height: 28

    Chamfer {
        anchors.fill: parent
        cut: 5
        strokeColor: button.active ? Theme.gold : (area.pressed ? Theme.alpha(Theme.gold, 0.6) : "transparent")
        fillTop: button.active ? Theme.alpha(Theme.primary, 0.3) : (area.pressed ? Theme.alpha(Theme.fg, 0.1) : "transparent")
    }

    Glyph {
        anchors.centerIn: parent
        kind: button.icon
        tint: button.active ? Theme.gold : Theme.fg
    }

    Rectangle {
        visible: button.badge > 0
        width: 7
        height: 7
        rotation: 45
        color: Theme.crimson
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 3
    }

    MouseArea {
        id: area
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            Ui.anchorTo(button);
            if (mouse.button === Qt.RightButton)
                button.rightClicked();
            else
                button.clicked();
        }
    }
}
