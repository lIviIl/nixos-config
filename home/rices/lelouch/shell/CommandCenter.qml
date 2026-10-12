import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The command center: a drawer on the right edge with one tab per page.
// The window is full height and never resizes; the card inside it is as tall as its page wants
// (up to the full height), and everything outside the card is click-through.
// The page keeps its own final size while the card grows around it, so nothing is re-laid out mid-animation.
PanelWindow {
    id: win

    readonly property int drawerWidth: 700
    readonly property real maxCard: height > 0 ? height : 900

    // Where the card is heading (the card follows it with an animation)
    readonly property real targetHeight: Math.min(maxCard, 98 + (pageLoader.item ? pageLoader.item.implicitHeight : 140))

    // Pages, in tab order
    readonly property var pages: [
        { id: "system", label: "SYSTEM" },
        { id: "controls", label: "CONTROLS" },
        { id: "connect", label: "CONNECT" },
        { id: "media", label: "MEDIA" }
    ]

    readonly property var pageComponents: ({
        system: systemPage,
        controls: controlsPage,
        connect: connectPage,
        media: mediaPage
    })

    visible: Ui.centerOpen || card.x < drawerWidth
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Clicks land on the drawer's final size; the region doesn't chase the animation
    mask: Region { item: hitbox }

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

    Item {
        id: hitbox
        x: 0
        y: 0
        width: win.drawerWidth
        height: win.targetHeight
    }

    Component {
        id: systemPage

        SystemPage {}
    }

    Component {
        id: controlsPage

        ControlsPage {}
    }

    Component {
        id: connectPage

        ConnectPage {}
    }

    Component {
        id: mediaPage

        MediaPage {}
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: card
            width: parent.width
            height: win.targetHeight

            x: Ui.centerOpen ? 0 : win.drawerWidth + 20
            opacity: Ui.centerOpen ? 1 : 0

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 260
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

            // Header: the title, a divider, the tab bar, close
            Item {
                id: header
                x: 24
                y: 18
                width: parent.width - 48
                height: 38

                Text {
                    id: title
                    anchors.verticalCenter: parent.verticalCenter
                    text: "COMMAND CENTER"
                    color: Theme.gold
                    font.family: Theme.serif
                    font.pixelSize: 15
                    font.letterSpacing: 2
                }

                Rectangle {
                    id: divider
                    anchors.left: title.right
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 26
                    color: Theme.alpha(Theme.gold, 0.7)
                }

                // The tab bar sits in its own frame
                Item {
                    id: tabBar
                    anchors.left: divider.right
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: tabRow.implicitWidth + 10
                    height: 34

                    Chamfer {
                        anchors.fill: parent
                        cut: 7
                        strokeColor: Theme.alpha(Theme.gold, 0.5)
                        fillTop: Theme.alpha(Theme.fg, 0.05)
                    }

                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: win.pages

                            Item {
                                id: tab

                                required property var modelData
                                readonly property bool active: Ui.centerPage === modelData.id

                                width: label.implicitWidth + 20
                                height: 26

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
                                    anchors.horizontalCenterOffset: 1
                                    text: tab.modelData.label
                                    color: tab.active ? Theme.onPrimary : Theme.alpha(Theme.fg, 0.85)
                                    font.family: Theme.mono
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.letterSpacing: 2
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Ui.centerPage = tab.modelData.id
                                }
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
                y: 62
                width: parent.width - 48
                height: 1
                color: Theme.alpha(Theme.gold, 0.6)
            }

            // The page area: clipped, so a growing card simply reveals the page
            Item {
                x: 24
                y: 74
                width: parent.width - 48
                height: parent.height - 98
                clip: true

                Loader {
                    id: pageLoader
                    width: parent.width

                    // The page's own height, not the animating card's
                    height: item ? item.implicitHeight : 140

                    active: Ui.centerOpen || card.x < win.drawerWidth
                    sourceComponent: win.pageComponents[Ui.centerPage] ?? systemPage

                    onLoaded: fadeIn.restart()
                }

                NumberAnimation {
                    id: fadeIn
                    target: pageLoader
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 180
                }
            }
        }
    }
}
