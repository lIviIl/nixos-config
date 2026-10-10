import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The command center: a drawer on the right edge with one tab per page.
PanelWindow {
    id: win

    readonly property int drawerWidth: 700
    property string page: "system"

    // Pages, in tab order. Each later pass adds one here.
    readonly property var pages: [
        { id: "system", label: "SYSTEM" },
        { id: "controls", label: "CONTROLS" }
    ]

    visible: Ui.centerOpen || card.x < drawerWidth
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        top: 56
        right: 12
        bottom: 12
    }

    implicitWidth: drawerWidth

    // Typing works once the drawer is clicked; it never grabs the keyboard on its own
    WlrLayershell.keyboardFocus: Ui.centerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    IpcHandler {
        target: "center"

        function toggle(): void {
            Ui.centerOpen = !Ui.centerOpen;
        }
    }

    Component {
        id: controlsPage

        ControlsPage {}
    }

    Component {
        id: systemPage

        SystemPage {}
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: card
            width: parent.width
            height: parent.height
            x: Ui.centerOpen ? 0 : win.drawerWidth + 20
            opacity: Ui.centerOpen ? 1 : 0

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity { NumberAnimation { duration: 180 } }

            Chamfer {
                anchors.fill: parent
                cut: 14
                strokeColor: Theme.alpha(Theme.gold, 0.9)
                fillTop: Theme.alpha(Theme.mix(Theme.bg, Theme.primary, 0.18), 0.96)
                fillBottom: Theme.alpha(Theme.bg, 0.96)
            }

            Chamfer {
                anchors.fill: parent
                anchors.margins: 5
                cut: 10
                strokeColor: Theme.alpha(Theme.primary, 0.4)
                fillTop: "transparent"
            }

            Item {
                focus: true
                Keys.onEscapePressed: Ui.centerOpen = false
            }

            // Header: title, tabs, close
            Item {
                x: 24
                y: 18
                width: parent.width - 48
                height: 34

                Text {
                    id: title
                    anchors.verticalCenter: parent.verticalCenter
                    text: "COMMAND CENTER"
                    color: Theme.gold
                    font.family: Theme.serif
                    font.pixelSize: 17
                    font.letterSpacing: 3
                }

                Row {
                    anchors.left: title.right
                    anchors.leftMargin: 26
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: win.pages

                        Item {
                            id: tab

                            required property var modelData
                            readonly property bool active: win.page === modelData.id

                            width: label.implicitWidth + 24
                            height: 28

                            Chamfer {
                                anchors.fill: parent
                                cut: 5
                                fillTop: Theme.primary
                                strokeColor: Theme.crimson
                                opacity: tab.active ? 1 : 0

                                Behavior on opacity { NumberAnimation { duration: 160 } }
                            }

                            Text {
                                id: label
                                anchors.centerIn: parent
                                text: tab.modelData.label
                                color: tab.active ? Theme.onPrimary : Theme.alpha(Theme.fg, 0.8)
                                font.family: Theme.mono
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 2
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.page = tab.modelData.id
                            }
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CLOSE"
                    color: Theme.alpha(Theme.fg, 0.7)
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Ui.centerOpen = false
                    }
                }
            }

            Rectangle {
                x: 24
                y: 58
                width: parent.width - 48
                height: 1
                color: Theme.alpha(Theme.gold, 0.6)
            }

            // The current page; unloaded while the drawer is closed
            Item {
                x: 24
                y: 70
                width: parent.width - 48
                height: parent.height - 94

                Loader {
                    anchors.fill: parent
                    active: Ui.centerOpen || card.x < win.drawerWidth
                    sourceComponent: win.page === "system" ? systemPage : controlsPage
                }
            }
        }
    }
}
