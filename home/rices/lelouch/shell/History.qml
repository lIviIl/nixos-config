pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Every notification the shell has received, kept across restarts.
// Action buttons work while the app's notification is still alive (this session).
Singleton {
    id: root

    property var entries: []                 // newest first
    property int counter: Math.floor(Date.now() / 1000) - 1780000000
    property var live: ({})                  // key -> Notification (this session only)
    property int liveRev: 0
    readonly property int maxEntries: 150
    readonly property string path: Quickshell.env("HOME") + "/.local/state/lelouch/notifications.json"

    function isLive(key) {
        liveRev;
        return !!live[key];
    }

    function add(n) {
        const key = counter++;
        const actions = [];
        for (let i = 0; i < n.actions.length; i++)
            actions.push({ id: n.actions[i].identifier, text: n.actions[i].text });

        const entry = {
            key: key,
            app: n.appName || "Unknown",
            summary: n.summary || "",
            body: (n.body || "").slice(0, 600),
            time: Date.now(),
            urgency: n.urgency === NotificationUrgency.Critical ? 2 : (n.urgency === NotificationUrgency.Low ? 0 : 1),
            actions: actions
        };

        live[key] = n;
        liveRev++;

        const all = [entry].concat(entries);
        const dropped = all.slice(maxEntries);
        for (let i = 0; i < dropped.length; i++)
            dismissLive(dropped[i].key);
        entries = all.slice(0, maxEntries);
        persist();
        return key;
    }

    function dismissLive(key) {
        const n = live[key];
        if (n) {
            try {
                n.dismiss();
            } catch (e) {
            }
            delete live[key];
            liveRev++;
        }
    }

    function remove(key) {
        dismissLive(key);
        entries = entries.filter(e => e.key !== key);
        persist();
    }

    function removeApp(app) {
        entries.filter(e => e.app === app).forEach(e => dismissLive(e.key));
        entries = entries.filter(e => e.app !== app);
        persist();
    }

    function clearAll() {
        Object.keys(live).forEach(k => dismissLive(k));
        entries = [];
        persist();
    }

    function invoke(key, id) {
        const n = live[key];
        if (!n)
            return;
        for (let i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === id) {
                n.actions[i].invoke();
                break;
            }
        }
        // Invoking a normal notification dismisses it
        if (!n.resident) {
            delete live[key];
            liveRev++;
            entries = entries.filter(e => e.key !== key);
            persist();
        }
    }

    function persist() {
        saveTimer.restart();
    }

    FileView {
        id: store
        path: root.path
        blockLoading: true
    }

    Component.onCompleted: {
        try {
            const saved = JSON.parse(store.text());
            if (Array.isArray(saved))
                entries = saved;
        } catch (e) {
        }
    }

    Timer {
        id: saveTimer
        interval: 800
        onTriggered: Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s" "$1" > "$2"', "sh", JSON.stringify(root.entries), root.path])
    }
}
