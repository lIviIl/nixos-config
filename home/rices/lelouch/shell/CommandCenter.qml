import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// The command center: a drawer on the right edge with three tabs (system, controls, connect).
// The window is full height and never resizes; the card inside it is as tall as its page wants
// (up to the full height), and everything outside the card is click-through.
// The page keeps its own final size while the card grows around it, so nothing is re-laid out mid-animation.
PanelWindow {
    id: win

    readonly property int drawerWidth: 700
    readonly property real maxCard: (screen ? screen.height : 1080) - 56 - 12

    // Above the page: title, tab bar and their gaps (118). Below it: 24 px of space, like the top.
    readonly property int topChrome: 118
    readonly property int bottomPad: 24
    readonly property int chrome: topChrome + bottomPad

    // The page's final height. When the screen is too short, the page shrinks to fit.
    readonly property real pageHeight: pageLoader.item ? Math.min(pageLoader.item.implicitHeight, maxCard - chrome) : 140

    // Where the card is heading (the card follows it with an animation)
    readonly property real targetHeight: chrome + pageHeight

    // The window is as tall as the card will be: it grows at once, and shrinks after the card's own animation
    property real winHeight: 200

    onTargetHeightChanged: {
        if (targetHeight > winHeight)
            winHeight = targetHeight;
        else
            shrink.restart();
    }

    Timer {
        id: shrink
        interval: 320
        onTriggered: win.winHeight = win.targetHeight
    }

    readonly property var pages: [
        { id: "system", label: "SYSTEM" },
        { id: "controls", label: "CONTROLS" },
        { id: "connect", label: "CONNECT" }
    ]

    readonly property var pageComponents: ({
        system: systemPage,
        controls: controlsPage,
        connect: connectPage
    })

    visible: Ui.centerOpen || card.x < drawerWidth
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore


    anchors {
        top: true
        right: true
    }

    margins {
        top: 56
        right: 12
        bottom: 12
    }

    implicitWidth: drawerWidth
    implicitHeight: winHeight

    // Typing works once the drawer is clicked; it never grabs the keyboard on its own
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    IpcHandler {
        target: "center"

        function toggle(): void {
            Ui.toggleCenter(Ui.centerPage);
        }
    }


    Component { id: systemPage; SystemPage {} }
    Component { id: controlsPage; ControlsPage {} }
    Component { id: connectPage; ConnectPage {} }

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

            CardFrame {
                anchors.fill: parent
            }

            Item {
                focus: true
                Keys.onEscapePressed: Ui.centerOpen = false
            }

            // Row 1: the title and close
            Item {
                x: 24
                y: 16
                width: parent.width - 48
                height: 30

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "COMMAND CENTER"
                    color: Theme.gold
                    font.family: Theme.serif
                    font.pixelSize: 17
                    font.letterSpacing: 3
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
                y: 52
                width: parent.width - 48
                height: 1
                color: Theme.alpha(Theme.gold, 0.7)
            }

            // Row 2: the tab bar, in its own frame, with equal tabs
            Item {
                id: tabBar
                x: 24
                y: 62
                width: parent.width - 48
                height: 34

                Chamfer {
                    anchors.fill: parent
                    cut: 7
                    strokeColor: Theme.alpha(Theme.gold, 0.5)
                    fillTop: Theme.alpha(Theme.fg, 0.05)
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 2

                    Repeater {
                        model: win.pages

                        Item {
                            id: tab

                            required property var modelData
                            readonly property bool active: Ui.centerPage === modelData.id

                            width: Math.floor((tabBar.width - 12 - 2 * (win.pages.length - 1)) / win.pages.length)
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

            Rectangle {
                x: 24
                y: 104
                width: parent.width - 48
                height: 1
                color: Theme.alpha(Theme.gold, 0.6)
            }

            // The page area: 14 px below the hairline, and 24 px above the bottom edge.
            // It is clipped, so a growing card simply reveals the page.
            Item {
                x: 24
                y: win.topChrome
                width: parent.width - 48
                height: parent.height - win.chrome
                clip: true

                Loader {
                    id: pageLoader
                    width: parent.width
                    height: win.pageHeight

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
