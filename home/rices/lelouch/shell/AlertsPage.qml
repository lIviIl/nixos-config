import QtQuick
import QtQuick.Layouts

Item {
    id: page

    implicitHeight: layout.implicitHeight

    // The history grouped by application, most recently active first
    readonly property var groups: {
        const map = {};
        const order = [];
        const list = History.entries;
        for (let i = 0; i < list.length; i++) {
            const e = list[i];
            if (!map[e.app]) {
                map[e.app] = [];
                order.push(e.app);
            }
            map[e.app].push(e);
        }
        return order.map(app => ({ app: app, items: map[app] }));
    }

    function stamp(ms) {
        const d = new Date(ms);
        return Agenda.key(d) === Agenda.key(new Date()) ? Qt.formatTime(d, "HH:mm") : Qt.formatDateTime(d, "d MMM  HH:mm");
    }

    // One notification: summary, time, its text, its action buttons, a delete link
    component AlertRow: Item {
        id: row

        property var entry: ({})
        property bool live: false

        signal removed()
        signal action(string id)

        width: parent ? parent.width : 0
        height: col.implicitHeight + 12

        Rectangle {
            x: 0
            y: 6
            width: 3
            height: parent.height - 12
            color: row.entry.urgency === 2 ? Theme.crimson : (row.entry.urgency === 0 ? Theme.outline : Theme.gold)
        }

        Column {
            id: col
            x: 14
            y: 6
            width: parent.width - 14
            spacing: 4

            Item {
                width: parent.width
                height: 18

                Text {
                    anchors.left: parent.left
                    anchors.right: when.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: row.entry.summary
                    color: Theme.fg
                    font.family: Theme.mono
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    id: when
                    anchors.right: remove.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.stamp(row.entry.time)
                    color: Theme.alpha(Theme.fg, 0.6)
                    font.family: Theme.mono
                    font.pixelSize: 10
                }

                Text {
                    id: remove
                    anchors.right: parent.right
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
                        onClicked: row.removed()
                    }
                }
            }

            Text {
                visible: row.entry.body !== ""
                width: parent.width
                text: row.entry.body
                color: Theme.alpha(Theme.fg, 0.8)
                font.family: Theme.mono
                font.pixelSize: 11
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Flow {
                visible: row.live && row.entry.actions.length > 0
                width: parent.width
                spacing: 6

                Repeater {
                    model: row.entry.actions

                    ActionButton {
                        required property var modelData

                        implicitHeight: 26
                        label: modelData.text
                        onClicked: row.action(modelData.id)
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 12

        SectionCard {
            icon: "bell"
            title: "NOTIFICATIONS"
            subtitle: History.entries.length + " saved"

            // A small text action; the first click asks, the second one clears
            RowLayout {
                visible: History.entries.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    id: clearAll

                    property bool armed: false

                    text: armed ? "CLICK AGAIN TO CLEAR ALL" : "CLEAR ALL"
                    color: armed ? Theme.crimson : Theme.alpha(Theme.fg, 0.7)
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 2

                    Timer {
                        id: disarm
                        interval: 3000
                        onTriggered: clearAll.armed = false
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (clearAll.armed) {
                                clearAll.armed = false;
                                History.clearAll();
                            } else {
                                clearAll.armed = true;
                                disarm.restart();
                            }
                        }
                    }
                }
            }

            Text {
                visible: History.entries.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "No notifications"
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 13
            }

            Scroller {
                visible: History.entries.length > 0
                maxHeight: 600

                Repeater {
                    model: page.groups

                    Column {
                        id: group

                        required property var modelData

                        width: parent.width
                        spacing: 2

                        // The application's name, with a hairline and a clear link
                        RowLayout {
                            width: parent.width
                            spacing: 10

                            Text {
                                text: group.modelData.app.toUpperCase() + "  (" + group.modelData.items.length + ")"
                                color: Theme.gold
                                font.family: Theme.mono
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 2
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Theme.alpha(Theme.gold, 0.35)
                            }

                            Text {
                                text: "CLEAR"
                                color: Theme.alpha(Theme.fg, 0.6)
                                font.family: Theme.mono
                                font.pixelSize: 10
                                font.bold: true

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: History.removeApp(group.modelData.app)
                                }
                            }
                        }

                        Repeater {
                            model: group.modelData.items

                            AlertRow {
                                required property var modelData

                                entry: modelData
                                live: History.isLive(modelData.key)
                                onRemoved: History.remove(modelData.key)
                                onAction: id => History.invoke(modelData.key, id)
                            }
                        }
                    }
                }
            }
        }
    }
}
