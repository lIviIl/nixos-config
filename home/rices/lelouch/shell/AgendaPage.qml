import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: page

    implicitHeight: layout.implicitHeight

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()
    property string selectedKey: Agenda.key(new Date())

    readonly property date selectedDate: new Date(selectedKey + "T00:00:00")

    function shift(n) {
        const d = new Date(viewYear, viewMonth + n, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    function goToday() {
        const d = new Date();
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
        selectedKey = Agenda.key(d);
    }

    function pick(date) {
        selectedKey = Agenda.key(date);
        if (date.getMonth() !== viewMonth || date.getFullYear() !== viewYear) {
            viewYear = date.getFullYear();
            viewMonth = date.getMonth();
        }
    }

    Component.onCompleted: Agenda.refreshIfStale()

    // One event: time (and date), title, place
    component EventRow: Item {
        id: ev

        property var item: ({})
        property bool showDate: false

        width: parent ? parent.width : 0
        height: Math.max(30, info.implicitHeight + 8)

        Column {
            x: 0
            y: 4
            width: 78
            spacing: 1

            Text {
                visible: ev.showDate
                text: Qt.formatDate(new Date(ev.item.startMs), "ddd d MMM").toUpperCase()
                color: Theme.alpha(Theme.fg, 0.65)
                font.family: Theme.mono
                font.pixelSize: 10
                font.bold: true
            }

            Text {
                text: ev.item.time
                color: Theme.gold
                font.family: Theme.mono
                font.pixelSize: 11
                font.bold: true
            }
        }

        Column {
            id: info
            x: 84
            y: 4
            width: parent.width - 84
            spacing: 1

            Text {
                width: parent.width
                text: ev.item.title
                color: Theme.fg
                font.family: Theme.mono
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                visible: ev.item.location !== ""
                width: parent.width
                text: ev.item.location
                color: Theme.alpha(Theme.fg, 0.6)
                font.family: Theme.mono
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }

    // One task: a checkbox, its priority and text, a delete link
    component TaskRow: Item {
        id: task

        property var item: ({})

        signal toggled()
        signal removed()

        width: parent ? parent.width : 0
        height: 30

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: task.toggled()
        }

        Chamfer {
            id: box
            x: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            cut: 4
            strokeColor: Theme.gold
            fillTop: task.item.done ? Theme.gold : "transparent"
        }

        Text {
            id: badge
            visible: task.item.priority !== ""
            anchors.left: box.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: task.item.priority
            color: Theme.crimson
            font.family: Theme.mono
            font.pixelSize: 12
            font.bold: true
        }

        Text {
            anchors.left: badge.visible ? badge.right : box.right
            anchors.leftMargin: 10
            anchors.right: remove.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: task.item.text
            color: task.item.done ? Theme.alpha(Theme.fg, 0.5) : Theme.fg
            font.family: Theme.mono
            font.pixelSize: 12
            font.bold: !task.item.done
            font.strikeout: task.item.done
        }

        Text {
            id: remove
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: "DEL"
            color: Theme.alpha(Theme.fg, 0.55)
            font.family: Theme.mono
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: task.removed()
            }
        }
    }

    GridLayout {
        id: layout
        anchors.fill: parent
        columns: 2
        columnSpacing: 12
        rowSpacing: 12

        // ---------------- CALENDAR ----------------
        SectionCard {
            Layout.fillHeight: true
            icon: "calendar"
            title: "CALENDAR"
            subtitle: Qt.formatDate(new Date(), "ddd d MMM").toUpperCase()

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 8

                ChevronButton {
                    direction: -1
                    onClicked: page.shift(-1)
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(new Date(page.viewYear, page.viewMonth, 1), "MMMM yyyy").toUpperCase()
                    color: Theme.fg
                    font.family: Theme.serif
                    font.pixelSize: 14
                    font.letterSpacing: 1
                }

                ChevronButton {
                    direction: 1
                    onClicked: page.shift(1)
                }
            }

            MonthGrid {
                Layout.fillWidth: true
                year: page.viewYear
                month: page.viewMonth
                selectedKey: page.selectedKey
                onPicked: date => page.pick(date)
            }

            ActionButton {
                Layout.alignment: Qt.AlignHCenter
                label: "TODAY"
                onClicked: page.goToday()
            }
        }

        // ---------------- AGENDA ----------------
        SectionCard {
            Layout.fillHeight: true
            icon: "list"
            title: "AGENDA"
            subtitle: Agenda.loading ? "UPDATING" : ""

            // No calendar link yet
            Text {
                visible: !Agenda.configured
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "No calendar link yet.\n\nIn Google Calendar: Settings, your calendar, Integrate calendar, copy the secret address in iCal format. Save it in ~/.config/lelouch/calendar-url, then press REFRESH."
                color: Theme.alpha(Theme.fg, 0.8)
                font.family: Theme.mono
                font.pixelSize: 11
            }

            Text {
                visible: Agenda.configured && Agenda.error !== ""
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: Agenda.error
                color: Theme.crimson
                font.family: Theme.mono
                font.pixelSize: 11
                font.bold: true
            }

            SectionLabel {
                visible: Agenda.configured
                text: Qt.formatDate(page.selectedDate, "ddd d MMM").toUpperCase()
            }

            Text {
                visible: Agenda.configured && (Agenda.byDay[page.selectedKey] || []).length === 0
                Layout.fillWidth: true
                text: "Nothing planned"
                color: Theme.alpha(Theme.fg, 0.6)
                font.family: Theme.mono
                font.pixelSize: 12
            }

            Scroller {
                visible: Agenda.configured && (Agenda.byDay[page.selectedKey] || []).length > 0
                maxHeight: 130

                Repeater {
                    model: Agenda.byDay[page.selectedKey] || []

                    EventRow {
                        required property var modelData

                        item: modelData
                    }
                }
            }

            SectionLabel {
                visible: Agenda.configured
                text: "COMING UP"
            }

            Text {
                visible: Agenda.configured && Agenda.upcoming.length === 0
                Layout.fillWidth: true
                text: "No upcoming events"
                color: Theme.alpha(Theme.fg, 0.6)
                font.family: Theme.mono
                font.pixelSize: 12
            }

            Scroller {
                visible: Agenda.configured && Agenda.upcoming.length > 0
                maxHeight: 190

                Repeater {
                    model: Agenda.upcoming.slice(0, 12)

                    EventRow {
                        required property var modelData

                        item: modelData
                        showDate: true
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            ActionButton {
                icon: "reboot"
                label: "REFRESH"
                enabled: !Agenda.loading
                onClicked: Agenda.refresh()
            }
        }

        // ---------------- TASKS ----------------
        SectionCard {
            Layout.columnSpan: 2
            icon: "check"
            title: "TASKS"
            subtitle: Tasks.open + " open"

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 8

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Chamfer {
                        anchors.fill: parent
                        cut: 5
                        strokeColor: Theme.alpha(Theme.gold, 0.7)
                        fillTop: "transparent"
                    }

                    TextInput {
                        id: newTask
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.onPrimary
                        font.family: Theme.mono
                        font.pixelSize: 13
                        clip: true

                        onAccepted: {
                            Tasks.add(text);
                            text = "";
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: newTask.text === ""
                        text: "Add a task (start with (A) for priority), then Enter"
                        color: Theme.alpha(Theme.fg, 0.5)
                        font.family: Theme.mono
                        font.pixelSize: 12
                    }
                }

                ActionButton {
                    Layout.preferredWidth: 80
                    Layout.fillHeight: true
                    label: "ADD"
                    onClicked: {
                        Tasks.add(newTask.text);
                        newTask.text = "";
                    }
                }
            }

            Text {
                visible: Tasks.items.length === 0
                Layout.fillWidth: true
                text: "No tasks yet. They live in ~/Sync/todo/todo.txt and sync with your phone."
                color: Theme.alpha(Theme.fg, 0.6)
                font.family: Theme.mono
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }

            Scroller {
                visible: Tasks.items.length > 0
                maxHeight: 150

                Repeater {
                    model: Tasks.items

                    TaskRow {
                        required property var modelData

                        item: modelData
                        onToggled: Tasks.toggle(modelData.index)
                        onRemoved: Tasks.remove(modelData.index)
                    }
                }
            }

            RowLayout {
                visible: Tasks.finished > 0
                Layout.fillWidth: true

                ActionButton {
                    label: "CLEAR DONE"
                    onClicked: Tasks.clearDone()
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: Tasks.finished + " done"
                    color: Theme.alpha(Theme.fg, 0.65)
                    font.family: Theme.mono
                    font.pixelSize: 11
                }
            }
        }
    }
}
