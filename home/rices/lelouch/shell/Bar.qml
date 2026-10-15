import QtQuick
import Quickshell

Variants {
    model: Quickshell.screens

    PanelWindow {
        property var modelData
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 8
            left: 12
            right: 12
        }

        implicitHeight: 40
        color: "transparent"

        Chamfer {
            anchors.fill: parent
            cut: 10
        }

        // Left: workspaces, what is playing (click: the media panel)
        Workspaces {
            id: workspaces
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
        }

        NowPlaying {
            anchors.left: workspaces.right
            anchors.leftMargin: 28
            anchors.verticalCenter: parent.verticalCenter
        }

        // Centre: the clock (click: the calendar), and the running timer
        ClockItem {
            id: clock
            anchors.centerIn: parent
        }

        FocusItem {
            anchors.left: clock.right
            anchors.leftMargin: 26
            anchors.verticalCenter: parent.verticalCenter
        }

        // Right: status, then the four panels
        Row {
            id: buttons
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            BarButton {
                icon: "pencil"
                active: Ui.popup === "notes"
                onClicked: Ui.togglePopup("notes")
            }

            BarButton {
                icon: "timer"
                active: Ui.popup === "focus"
                onClicked: Ui.togglePopup("focus")
            }

            BarButton {
                icon: "bell"
                active: Ui.popup === "alerts"
                badge: History.unread
                onClicked: Ui.togglePopup("alerts")
            }

            BarButton {
                icon: "apps"
                active: Ui.centerOpen
                onClicked: Ui.toggleCenter(Ui.centerPage)
            }
        }

        Status {
            anchors.right: buttons.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
