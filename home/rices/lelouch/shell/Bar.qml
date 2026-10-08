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
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
        }

        ClockItem {
            anchors.centerIn: parent
        }

        Status {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
