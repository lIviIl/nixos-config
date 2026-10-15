pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Calendar events from your private calendar link (~/.config/lelouch/calendar-url),
// expanded by `lelouch-agenda`. Refreshed when the Agenda tab opens and every 15 minutes while it is open.
Singleton {
    id: root

    property bool loading: false
    property bool configured: true
    property string error: ""
    property real fetchedAt: 0

    property var byDay: ({})        // "YYYY-MM-DD" -> events on that day
    property var upcoming: []       // events from now on, soonest first

    function pad(n) {
        return (n < 10 ? "0" : "") + n;
    }

    function key(d) {
        return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate());
    }

    function refreshIfStale() {
        if (Date.now() - fetchedAt > 300000)
            refresh();
    }

    function refresh() {
        if (fetch.running)
            return;
        const now = new Date();
        const from = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 45);
        const to = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 400);
        loading = true;
        error = "";
        configured = true;
        fetch.command = ["lelouch-agenda", key(from), key(to)];
        fetch.running = true;
    }

    function ingest(text) {
        if (text.trim() === "")
            return;

        let list = [];
        try {
            list = JSON.parse(text);
        } catch (e) {
            error = "Could not read the calendar";
            return;
        }

        const index = {};
        const flat = [];

        for (let i = 0; i < list.length; i++) {
            const e = list[i];
            const start = e.allDay ? new Date(e.start + "T00:00:00") : new Date(e.start);
            const end = e.allDay ? new Date(e.end + "T00:00:00") : new Date(e.end);
            const firstDay = new Date(start.getFullYear(), start.getMonth(), start.getDate());
            const lastDay = new Date(end.getFullYear(), end.getMonth(), end.getDate());

            // An end exactly at midnight belongs to the day before
            if (e.allDay || (end > start && end.getHours() === 0 && end.getMinutes() === 0))
                lastDay.setDate(lastDay.getDate() - 1);
            if (lastDay < firstDay)
                lastDay.setTime(firstDay.getTime());

            const item = {
                title: e.title || "(no title)",
                location: e.location || "",
                allDay: e.allDay,
                startMs: start.getTime(),
                endMs: end.getTime(),
                time: e.allDay ? "ALL DAY" : Qt.formatTime(start, "HH:mm")
            };
            flat.push(item);

            for (let d = new Date(firstDay); d <= lastDay; d.setDate(d.getDate() + 1)) {
                const k = key(d);
                if (!index[k])
                    index[k] = [];
                index[k].push(item);
            }
        }

        for (const k in index)
            index[k].sort((a, b) => (b.allDay - a.allDay) || (a.startMs - b.startMs));

        byDay = index;
        const now = Date.now();
        upcoming = flat.filter(e => e.endMs >= now).sort((a, b) => a.startMs - b.startMs).slice(0, 40);
        fetchedAt = now;
    }

    Process {
        id: fetch

        stdout: StdioCollector {
            onStreamFinished: root.ingest(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t.indexOf("no-url") >= 0)
                    root.configured = false;
                else if (t !== "")
                    root.error = "Could not fetch the calendar: " + t.split("\n").pop().slice(0, 140);
            }
        }

        onExited: root.loading = false
    }

    Timer {
        interval: 900000
        running: Ui.popup === "calendar"
        repeat: true
        onTriggered: root.refresh()
    }
}
