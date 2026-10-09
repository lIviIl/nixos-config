pragma Singleton

import QtQuick
import Quickshell

// Number formatting
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
}
