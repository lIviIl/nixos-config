import QtQuick
import QtQuick.Layouts

// A length of time. The chevrons step it by 15 seconds; or click the number and type
// (25 = minutes, 25:30, 1:30:00, 90s, 5m, 2h) and press Enter.
Item {
    id: field

    property string label: ""
    property int seconds: 60
    property int step: 15
    property bool editing: false

    signal edited(int seconds)

    Layout.fillWidth: true
    Layout.preferredHeight: 34

    function commit(text) {
        const s = Fmt.parseDuration(text);
        if (s > 0)
            field.edited(s);
        editing = false;
    }

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: field.label
        color: Theme.alpha(Theme.fg, 0.8)
        font.family: Theme.mono
        font.pixelSize: 12
        font.bold: true
        font.letterSpacing: 1
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        ChevronButton {
            direction: -1
            onClicked: field.edited(field.seconds - field.step)
        }

        Item {
            width: 96
            height: 30

            Chamfer {
                anchors.fill: parent
                cut: 6
                strokeColor: Theme.alpha(Theme.gold, field.editing ? 1 : 0.5)
                fillTop: "transparent"
            }

            Text {
                visible: !field.editing
                anchors.centerIn: parent
                text: Fmt.hms(field.seconds)
                color: Theme.fg
                font.family: Theme.mono
                font.pixelSize: 13
                font.bold: true
            }

            TextInput {
                id: input
                visible: field.editing
                anchors.fill: parent
                anchors.margins: 6
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                selectionColor: Theme.primary
                selectedTextColor: Theme.onPrimary
                font.family: Theme.mono
                font.pixelSize: 13
                font.bold: true

                onAccepted: field.commit(text)
                onActiveFocusChanged: {
                    if (!activeFocus)
                        field.editing = false;
                }
                Keys.onEscapePressed: field.editing = false
            }

            MouseArea {
                anchors.fill: parent
                visible: !field.editing
                cursorShape: Qt.IBeamCursor

                onClicked: {
                    field.editing = true;
                    input.text = Fmt.hms(field.seconds);
                    input.forceActiveFocus();
                    input.selectAll();
                }
            }
        }

        ChevronButton {
            direction: 1
            onClicked: field.edited(field.seconds + field.step)
        }
    }
}
