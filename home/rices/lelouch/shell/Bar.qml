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

        // Left: the panels, the workspaces, the window layout, then what is playing
        Row {
            id: left
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            BarButton {
                icon: "apps"
                active: Ui.centerOpen
                onClicked: Ui.toggleCenter(Ui.centerPage)
            }

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

            BarDivider {}

            Workspaces {}

            BarDivider {}

            // The window layout: click for the list, right-click to cycle
            BarButton {
                icon: "tile-" + Tiling.current
                active: Ui.popup === "layout"
                onClicked: Ui.togglePopup("layout")
                onRightClicked: Tiling.cycle()
            }
        }

        NowPlaying {
            anchors.left: left.right
            anchors.leftMargin: 22
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

        // Right: status only
        Status {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
