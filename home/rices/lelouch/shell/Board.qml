pragma Singleton

import QtQuick
import Quickshell

// The whiteboard's strokes, kept as data (not pixels), so they survive closing the window, restarts and resizing.
// Points run from 0 to 1 across the board. Colours are theme roles (fg, gold, crimson, primary).
// A stroke is { c: role, w: width, e: isEraser, p: [x0, y0, x1, y1, ...] }.
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/Sync/notes/whiteboard.json"

    property var strokes: []
    property int count: 0
    property int revision: 0        // bumped whenever the whole drawing has to be redrawn
    property var current: null

    function round(v) {
        return Math.round(v * 10000) / 10000;
    }

    function begin(role, width, erase, x, y) {
        current = { c: role, w: width, e: erase, p: [round(x), round(y)] };
        strokes.push(current);
        count = strokes.length;
    }

    function extend(x, y) {
        if (current)
            current.p.push(round(x), round(y));
    }

    function end() {
        current = null;
        store.save(JSON.stringify(strokes));
    }

    function undo() {
        if (strokes.length === 0)
            return;
        strokes.pop();
        count = strokes.length;
        revision++;
        store.save(JSON.stringify(strokes));
    }

    function clear() {
        strokes = [];
        count = 0;
        revision++;
        store.save("[]");
    }

    TextStore {
        id: store
        path: root.path
        watch: false
        delay: 800
        onLoaded: text => {
            try {
                const saved = JSON.parse(text);
                if (Array.isArray(saved)) {
                    root.strokes = saved;
                    root.count = saved.length;
                    root.revision++;
                }
            } catch (e) {
            }
        }
    }
}
