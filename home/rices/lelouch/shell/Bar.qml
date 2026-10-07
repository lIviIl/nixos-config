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

        implicitHeight: 38
        color: "transparent"

        Workspaces {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        Clock {
            anchors.centerIn: parent
        }

        Status {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
