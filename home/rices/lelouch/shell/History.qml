pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Every notification the shell has received, kept across restarts.
// Action buttons work while the app's notification is still alive (this session).
Singleton {
    id: root

    property var entries: []                 // newest first
    property int counter: Math.floor(Date.now() / 1000) - 1780000000
    property var live: ({})                  // key -> Notification (this session only)
    property int liveRev: 0
    property int unread: 0
    readonly property int maxEntries: 150

    function isLive(key) {
        liveRev;
        return !!live[key];
    }

    function markRead() {
        unread = 0;
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
        if (Ui.popup !== "alerts")
            unread++;

        const all = [entry].concat(entries);
        all.slice(maxEntries).forEach(e => dismissLive(e.key));
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
        unread = 0;
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
        store.save(JSON.stringify(entries));
    }

    function restore(text) {
        if (entries.length > 0)
            return;
        try {
            const saved = JSON.parse(text);
            if (Array.isArray(saved))
                entries = saved;
        } catch (e) {
        }
    }

    TextStore {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/lelouch/notifications.json"
        watch: false
        delay: 800
        onLoaded: text => root.restore(text)
    }
}
