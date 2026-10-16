import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Quick notes and a large whiteboard in one centred overlay. Opened with Super+N or the pencil in the bar.
Panel {
    id: pad

    modal: false

    cardWidth: Math.max(640, Math.min(1180, width - 120))
    cardHeight: Math.max(480, Math.min(740, height - 140))

    IpcHandler {
        target: "notes"

        function toggle(): void {
            Ui.togglePopup("notes");
        }
    }

    Text {
        anchors.top: parent.top
        anchors.topMargin: 6
        anchors.right: parent.right
        anchors.rightMargin: 26
        text: "CLOSE"
        color: Theme.alpha(Theme.fg, 0.6)
        font.family: Theme.mono
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 2

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: pad.open = false
        }
    }

    Connections {
        target: Ui

        function onPopupChanged() {
            pad.open = Ui.popup === "notes";
        }
    }

    onOpenChanged: {
        if (!open && Ui.popup === "notes")
            Ui.popup = "";
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

    RowLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 16

        Keys.onEscapePressed: pad.open = false

        // ---------------- QUICK NOTES ----------------
        SectionCard {
            property int editing: -1

            Layout.fillWidth: false
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            icon: "pencil"
            title: "QUICK NOTES"
            subtitle: Notes.notes.length + " saved"

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 120

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

                    Component.onCompleted: text = Notes.draft
                    onTextChanged: Notes.draft = text

                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                            Notes.commitDraft();
                            event.accepted = true;
                        }
                    }
                }

                // Follow the draft when it is cleared after saving
                Connections {
                    target: Notes

                    function onDraftChanged() {
                        if (composer.text !== Notes.draft)
                            composer.text = Notes.draft;
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
                    onClicked: Notes.commitDraft()
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "autosaved"
                    color: Theme.alpha(Theme.fg, 0.5)
                    font.family: Theme.mono
                    font.pixelSize: 10
                }
            }

            Scroller {
                id: noteList
                visible: Notes.notes.length > 0
                maxHeight: Math.max(120, pad.cardHeight - 340)

                Repeater {
                    model: Notes.notes

                    NoteRow {
                        required property string modelData
                        required property int index

                        text: modelData
                        editing: noteList.parent.parent.editing === index
                        onEditRequested: noteList.parent.parent.editing = index
                        onCancelled: noteList.parent.parent.editing = -1

                        onSaved: text => {
                            Notes.update(index, text);
                            noteList.parent.parent.editing = -1;
                        }

                        onRemoved: {
                            noteList.parent.parent.editing = -1;
                            Notes.remove(index);
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // ---------------- WHITEBOARD ----------------
        SectionCard {
            Layout.fillHeight: true
            Layout.preferredWidth: 640
            icon: "pencil"
            title: "WHITEBOARD"
            subtitle: Board.count + " strokes"

            Whiteboard {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
