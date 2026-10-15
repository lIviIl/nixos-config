pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Quick notes in one Markdown file, with --- between notes, newest first.
// Put ~/Sync/notes in Syncthing to read and edit them on your phone.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Sync/notes"
    readonly property string path: dir + "/notes.md"

    property var notes: []

    function parse(text) {
        return text.split(/\n---\n/).map(s => s.trim()).filter(s => s !== "");
    }

    function save(list) {
        notes = list;
        const body = list.length > 0 ? list.join("\n---\n") + "\n" : "";
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s" "$1" > "$2.tmp" && mv "$2.tmp" "$2"', "sh", body, path]);
    }

    function add(text) {
        const t = text.trim();
        if (t === "")
            return;
        save([t].concat(notes));
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

    FileView {
        id: file
        path: root.path
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    readonly property string fileText: {
        try {
            return file.text();
        } catch (e) {
            return "";
        }
    }

    onFileTextChanged: notes = parse(fileText)
    Component.onCompleted: notes = parse(fileText)
}
