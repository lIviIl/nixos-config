pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// A todo.txt file, kept in step with your phone by Syncthing.
// If your Syncthing folder is somewhere else, change `path`.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/Sync/todo/todo.txt"

    property var rawLines: []

    readonly property var items: {
        const out = [];
        for (let i = 0; i < rawLines.length; i++)
            out.push(parse(rawLines[i], i));
        out.sort((a, b) => {
            if (a.done !== b.done)
                return a.done ? 1 : -1;
            if ((a.priority === "") !== (b.priority === ""))
                return a.priority === "" ? 1 : -1;
            if (a.priority !== b.priority)
                return a.priority < b.priority ? -1 : 1;
            return a.index - b.index;
        });
        return out;
    }

    readonly property int open: items.filter(t => !t.done).length
    readonly property int finished: items.filter(t => t.done).length

    function pad(n) {
        return (n < 10 ? "0" : "") + n;
    }

    function today() {
        const d = new Date();
        return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate());
    }

    // todo.txt: "x 2026-10-12 2026-10-10 text" is done, "(A) 2026-10-10 text" has a priority.
    // The priority may come before or after the creation date.
    function parse(line, index) {
        let text = line;
        let done = false;
        let priority = "";

        if (/^x\s/.test(text)) {
            done = true;
            text = text.replace(/^x\s+(\d{4}-\d{2}-\d{2}\s+)?/, "");
        }

        let m = text.match(/^\(([A-Z])\)\s+/);
        if (m) {
            priority = m[1];
            text = text.slice(m[0].length);
        }

        text = text.replace(/^\d{4}-\d{2}-\d{2}\s+/, "");

        if (priority === "") {
            m = text.match(/^\(([A-Z])\)\s+/);
            if (m) {
                priority = m[1];
                text = text.slice(m[0].length);
            }
        }

        return { index: index, done: done, priority: priority, text: text };
    }

    function save() {
        const body = rawLines.length > 0 ? rawLines.join("\n") + "\n" : "";
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s" "$1" > "$2.tmp" && mv "$2.tmp" "$2"', "sh", body, path]);
    }

    function add(text) {
        const t = text.trim();
        if (t === "")
            return;
        const m = t.match(/^\(([A-Z])\)\s+(.*)$/);
        const line = m ? "(" + m[1] + ") " + today() + " " + m[2] : today() + " " + t;
        rawLines = rawLines.concat([line]);
        save();
    }

    function toggle(index) {
        const lines = rawLines.slice();
        const line = lines[index];
        if (/^x\s/.test(line))
            lines[index] = line.replace(/^x\s+(\d{4}-\d{2}-\d{2}\s+)?/, "");
        else
            lines[index] = "x " + today() + " " + line.replace(/^\([A-Z]\)\s+/, "");
        rawLines = lines;
        save();
    }

    function remove(index) {
        rawLines = rawLines.filter((l, i) => i !== index);
        save();
    }

    function clearDone() {
        rawLines = rawLines.filter(l => !/^x\s/.test(l));
        save();
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

    onFileTextChanged: rawLines = fileText.split("\n").filter(l => l.trim() !== "")
    Component.onCompleted: rawLines = fileText.split("\n").filter(l => l.trim() !== "")
}
