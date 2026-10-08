import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Scope {
    NotificationServer {
        id: server

        onNotification: notification => {
            notification.tracked = true;
        }
    }

    PanelWindow {
        visible: server.trackedNotifications.values.length > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            right: true
        }

        margins {
            top: 56
            right: 12
        }

        implicitWidth: 380
        implicitHeight: stack.implicitHeight

        Column {
            id: stack
            width: parent.width
            spacing: 8

            Repeater {
                model: server.trackedNotifications

                Toast {}
            }
        }
    }
}
