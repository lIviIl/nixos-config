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

    // Header, tab bar and padding around the page: 14 px of space above it and 14 px below
    readonly property int chrome: 132

    // Where the card is heading (the card follows it with an animation)
    readonly property real targetHeight: Math.min(maxCard, chrome + (pageLoader.item ? pageLoader.item.implicitHeight : 140))

    // Pages, in tab order
    readonly property var pages: [
        { id: "system", label: "SYSTEM" },
        { id: "controls", label: "CONTROLS" },
        { id: "connect", label: "CONNECT" },
        { id: "media", label: "MEDIA" },
        { id: "agenda", label: "AGENDA" },
        { id: "focus", label: "FOCUS" },
        { id: "notes", label: "NOTES" },
        { id: "alerts", label: "ALERTS" }
    ]

    readonly property var pageComponents: ({
        system: systemPage,
        controls: controlsPage,
        connect: connectPage,
        media: mediaPage,
        agenda: agendaPage,
        focus: focusPage,
        notes: notesPage,
        alerts: alertsPage
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

    Component { id: systemPage; SystemPage {} }
    Component { id: controlsPage; ControlsPage {} }
    Component { id: connectPage; ConnectPage {} }
    Component { id: mediaPage; MediaPage {} }
    Component { id: agendaPage; AgendaPage {} }
    Component { id: focusPage; FocusPage {} }
    Component { id: notesPage; NotesPage {} }
    Component { id: alertsPage; AlertsPage {} }

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
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.5
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

            // The page area: 14 px below the hairline and 14 px above the bottom edge.
            // It is clipped, so a growing card simply reveals the page.
            Item {
                x: 24
                y: 118
                width: parent.width - 48
                height: parent.height - win.chrome
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
