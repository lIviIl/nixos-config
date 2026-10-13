import QtQuick

// One month: ISO week numbers, weekday headers, day cells with event markers.
Item {
    id: grid

    property int year: 2026
    property int month: 0
    property string selectedKey: ""

    signal picked(var date)

    readonly property real weekW: 28
    readonly property real cellW: Math.floor((width - weekW) / 7)
    readonly property real cellH: 34
    readonly property real headH: 20
    readonly property real contentW: weekW + 7 * cellW
    readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7
    readonly property string todayKey: Agenda.key(new Date())
    readonly property var dayNames: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]

    implicitHeight: headH + 4 + 6 * cellH

    function dateAt(row, col) {
        return new Date(year, month, 1 - offset + row * 7 + col);
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7);
    }

    // Everything sits in one block, centred in the card
    Item {
        x: Math.round((grid.width - grid.contentW) / 2)
        width: grid.contentW
        height: grid.height

        // Weekday headers
        Row {
            height: grid.headH

            Item {
                width: grid.weekW
                height: grid.headH

                Text {
                    anchors.centerIn: parent
                    text: "WK"
                    color: Theme.alpha(Theme.gold, 0.8)
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Repeater {
                model: grid.dayNames

                Item {
                    required property string modelData

                    width: grid.cellW
                    height: grid.headH

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData
                        color: Theme.alpha(Theme.fg, 0.6)
                        font.family: Theme.mono
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }

        Column {
            y: grid.headH + 4

            Repeater {
                model: 6

                Row {
                    id: weekRow

                    required property int index

                    height: grid.cellH

                    Item {
                        width: grid.weekW
                        height: grid.cellH

                        Text {
                            anchors.centerIn: parent
                            text: grid.isoWeek(grid.dateAt(weekRow.index, 3))
                            color: Theme.alpha(Theme.gold, 0.7)
                            font.family: Theme.mono
                            font.pixelSize: 10
                        }
                    }

                    Repeater {
                        model: 7

                        Item {
                            id: cell

                            required property int index

                            readonly property var date: grid.dateAt(weekRow.index, index)
                            readonly property string key: Agenda.key(date)
                            readonly property bool inMonth: date.getMonth() === grid.month
                            readonly property bool isToday: key === grid.todayKey
                            readonly property bool selected: key === grid.selectedKey
                            readonly property int count: (Agenda.byDay[key] || []).length

                            width: grid.cellW
                            height: grid.cellH

                            // Today: filled, with a crimson edge
                            Chamfer {
                                visible: cell.isToday
                                anchors.fill: parent
                                anchors.margins: 2
                                cut: 5
                                strokeColor: Theme.crimson
                                fillTop: Theme.primary
                            }

                            // The selected day: a gold ring
                            Chamfer {
                                visible: cell.selected && !cell.isToday
                                anchors.fill: parent
                                anchors.margins: 2
                                cut: 5
                                strokeWidth: 1.5
                                strokeColor: Theme.gold
                                fillTop: "transparent"
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                visible: hover.hovered && !cell.isToday && !cell.selected
                                color: Theme.alpha(Theme.fg, 0.08)
                            }

                            // The number is centred in the cell (nudged up when there are markers)
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: cell.count > 0 && cell.inMonth ? -3 : 0
                                text: cell.date.getDate()
                                color: cell.isToday ? Theme.onPrimary : (cell.inMonth ? Theme.fg : Theme.alpha(Theme.fg, 0.3))
                                font.family: Theme.mono
                                font.pixelSize: 12
                                font.bold: cell.isToday || cell.selected
                            }

                            // Event markers: up to three small diamonds
                            Row {
                                visible: cell.count > 0 && cell.inMonth
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 5
                                spacing: 3

                                Repeater {
                                    model: Math.min(cell.count, 3)

                                    Rectangle {
                                        width: 4
                                        height: 4
                                        rotation: 45
                                        color: cell.isToday ? Theme.onPrimary : Theme.gold
                                    }
                                }
                            }

                            HoverHandler {
                                id: hover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: grid.picked(cell.date)
                            }
                        }
                    }
                }
            }
        }
    }
}
