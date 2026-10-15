pragma Singleton

import QtQuick
import Quickshell

// Number and text helpers
Singleton {
    function bytes(n) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (n >= 1024 && i < units.length - 1) {
            n /= 1024;
            i++;
        }
        return (i === 0 ? Math.round(n) : n.toFixed(n >= 100 ? 0 : 1)) + " " + units[i];
    }

    function rate(n) {
        return bytes(n) + "/s";
    }

    function mhz(m) {
        return m >= 1000 ? (m / 1000).toFixed(2) + " GHz" : Math.round(m) + " MHz";
    }

    function minutes(m) {
        if (!isFinite(m) || m <= 0)
            return "--";
        const h = Math.floor(m / 60);
        const mm = Math.round(m % 60);
        return h + "h " + (mm < 10 ? "0" : "") + mm + "m";
    }

    // m:ss, for media
    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }

    // mm:ss, or h:mm:ss from an hour up
    function hms(total) {
        const s = Math.max(0, Math.floor(total));
        const h = Math.floor(s / 3600);
        const m = Math.floor(s % 3600 / 60);
        const pad = n => (n < 10 ? "0" : "") + n;
        return (h > 0 ? h + ":" + pad(m) : pad(m)) + ":" + pad(s % 60);
    }

    // "25" is minutes, "25:30" is m:ss, "1:30:00" is h:mm:ss, "90s", "5m", "2h" also work. -1 if unreadable.
    function parseDuration(text) {
        const t = text.trim().toLowerCase();
        let m = t.match(/^(\d+)$/);
        if (m)
            return Number(m[1]) * 60;
        m = t.match(/^(\d+):(\d{1,2})$/);
        if (m)
            return Number(m[1]) * 60 + Number(m[2]);
        m = t.match(/^(\d+):(\d{1,2}):(\d{1,2})$/);
        if (m)
            return Number(m[1]) * 3600 + Number(m[2]) * 60 + Number(m[3]);
        m = t.match(/^(\d+)\s*(s|sec|m|min|h)$/);
        if (m) {
            const n = Number(m[1]);
            return m[2].startsWith("h") ? n * 3600 : (m[2].startsWith("m") ? n * 60 : n);
        }
        return -1;
    }

    // d hh:mm:ss
    function uptime(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        const d = Math.floor(s / 86400);
        const pad = n => (n < 10 ? "0" : "") + n;
        return (d > 0 ? d + "d " : "") + pad(Math.floor(s % 86400 / 3600)) + ":" + pad(Math.floor(s % 3600 / 60)) + ":" + pad(s % 60);
    }

    // nmcli's terse output: fields split on ":", with "\:" and "\\" as escapes
    function splitTerse(line) {
        const parts = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) {
                cur += line[i + 1];
                i++;
            } else if (c === ":") {
                parts.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        parts.push(cur);
        return parts;
    }
}
