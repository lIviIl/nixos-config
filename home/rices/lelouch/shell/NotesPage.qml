import QtQuick
import QtQuick.Layouts

Item {
    id: page

    implicitHeight: layout.implicitHeight

    property int editing: -1

    function addNote() {
        Notes.add(composer.text);
        composer.text = "";
    }

    // One note: its text, or an editor, with small text actions
    component NoteRow: Item {
        id: note

        property string text: ""
        property bool editing: false

        signal editRequested()
        signal saved(string text)
        signal cancelled()
        signal removed()

        width: parent ? parent.width : 0
        height: col.implicitHeight + 14

        Rectangle {
            x: 0
            y: 6
            width: 3
            height: parent.height - 12
            color: Theme.gold
        }

        Column {
            id: col
            x: 14
            y: 7
            width: parent.width - 14
            spacing: 6

            Text {
                visible: !note.editing
                width: parent.width
                text: note.text
                color: Theme.fg
                font.family: Theme.mono
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 6
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Item {
                visible: note.editing
                width: parent.width
                height: 90

                Chamfer {
                    anchors.fill: parent
                    cut: 5
                    strokeColor: Theme.alpha(Theme.gold, 0.7)
                    fillTop: "transparent"
                }

                TextEdit {
                    id: editor
                    anchors.fill: parent
                    anchors.margins: 10
                    wrapMode: TextEdit.Wrap
                    color: Theme.fg
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.onPrimary
                    font.family: Theme.mono
                    font.pixelSize: 12
                    clip: true

                    onVisibleChanged: {
                        if (visible) {
                            text = note.text;
                            forceActiveFocus();
                        }
                    }
                }
            }

            Row {
                spacing: 16

                Text {
                    visible: !note.editing
                    text: "EDIT"
                    color: Theme.gold
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: note.editRequested()
                    }
                }

                Text {
                    visible: !note.editing
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
                        onClicked: note.removed()
                    }
                }

                Text {
                    visible: note.editing
                    text: "SAVE"
                    color: Theme.gold
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: note.saved(editor.text)
                    }
                }

                Text {
                    visible: note.editing
                    text: "CANCEL"
                    color: Theme.alpha(Theme.fg, 0.55)
                    font.family: Theme.mono
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: note.cancelled()
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 12

        // ---------------- QUICK NOTES ----------------
        SectionCard {
            icon: "pencil"
            title: "QUICK NOTES"
            subtitle: Notes.notes.length + " saved"

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 84

                Chamfer {
                    anchors.fill: parent
                    cut: 6
                    strokeColor: Theme.alpha(Theme.gold, 0.7)
                    fillTop: "transparent"
                }

                TextEdit {
                    id: composer
                    anchors.fill: parent
                    anchors.margins: 10
                    wrapMode: TextEdit.Wrap
                    color: Theme.fg
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.onPrimary
                    font.family: Theme.mono
                    font.pixelSize: 12
                    clip: true

                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                            page.addNote();
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 10
                    visible: composer.text === ""
                    text: "A note or an idea...  (Ctrl+Enter saves)"
                    color: Theme.alpha(Theme.fg, 0.5)
                    font.family: Theme.mono
                    font.pixelSize: 12
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34

                ActionButton {
                    icon: "check"
                    label: "SAVE NOTE"
                    enabled: composer.text.trim() !== ""
                    onClicked: page.addNote()
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "~/Sync/notes/notes.md"
                    color: Theme.alpha(Theme.fg, 0.5)
                    font.family: Theme.mono
                    font.pixelSize: 10
                }
            }

            Scroller {
                visible: Notes.notes.length > 0
                maxHeight: 190

                Repeater {
                    model: Notes.notes

                    NoteRow {
                        required property string modelData
                        required property int index

                        text: modelData
                        editing: page.editing === index
                        onEditRequested: page.editing = index
                        onCancelled: page.editing = -1

                        onSaved: text => {
                            Notes.update(index, text);
                            page.editing = -1;
                        }

                        onRemoved: {
                            page.editing = -1;
                            Notes.remove(index);
                        }
                    }
                }
            }
        }

        // ---------------- WHITEBOARD ----------------
        SectionCard {
            icon: "pencil"
            title: "WHITEBOARD"

            Whiteboard {}
        }
    }
}
