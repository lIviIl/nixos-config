pragma Singleton

import QtQuick
import Quickshell

// Quick notes in one Markdown file, with --- between notes, newest first.
// The note you are still typing (the draft) is saved too, so nothing is lost when a window closes.
// Put ~/Sync/notes in Syncthing to read and edit the notes on your phone.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Sync/notes"

    property var notes: []
    property string draft: ""

    function parse(text) {
        return text.split(/\n---\n/).map(s => s.trim()).filter(s => s !== "");
    }

    function save(list) {
        notes = list;
        notesStore.save(list.length > 0 ? list.join("\n---\n") + "\n" : "");
    }

    function add(text) {
        const t = text.trim();
        if (t !== "")
            save([t].concat(notes));
    }

    // Turn the draft into a note
    function commitDraft() {
        add(draft);
        draft = "";
    }

    function update(index, text) {
        const t = text.trim();
        if (t === "") {
            remove(index);
            return;
        }
        const list = notes.slice();
        list[index] = t;
        save(list);
    }

    function remove(index) {
        save(notes.filter((n, i) => i !== index));
    }

    onDraftChanged: draftStore.save(draft)

    TextStore {
        id: notesStore
        path: root.dir + "/notes.md"
        onLoaded: text => root.notes = root.parse(text)
    }

    TextStore {
        id: draftStore
        path: Quickshell.env("HOME") + "/.local/state/lelouch/draft.txt"
        watch: false
        onLoaded: text => {
            if (root.draft === "")
                root.draft = text;
        }
    }
}
