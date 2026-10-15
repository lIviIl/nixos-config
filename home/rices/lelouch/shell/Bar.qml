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

        ClockItem {
            id: clock
            anchors.centerIn: parent
        }

        // The running timer, beside the clock
        FocusItem {
            anchors.left: clock.right
            anchors.leftMargin: 26
            anchors.verticalCenter: parent.verticalCenter
        }

        CenterButton {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
        }

        Status {
            anchors.right: parent.right
            anchors.rightMargin: 58
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
