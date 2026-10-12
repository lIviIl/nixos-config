pragma Singleton

import QtQuick
import Quickshell

// Volume changes shared by the bar, the volume panel and the Controls tab:
// the lowest setting mutes, and moving up from it unmutes.
Singleton {
    function applyVolume(node, v) {
        if (!node || !node.audio)
            return;
        const id = String(node.id);
        if (v <= 0.005) {
            Quickshell.execDetached(["wpctl", "set-volume", id, "0"]);
            if (!node.audio.muted)
                Quickshell.execDetached(["wpctl", "set-mute", id, "1"]);
        } else {
            if (node.audio.muted)
                Quickshell.execDetached(["wpctl", "set-mute", id, "0"]);
            Quickshell.execDetached(["wpctl", "set-volume", id, Math.min(1, v).toFixed(2)]);
        }
    }

    // One scroll notch
    function step(node, direction) {
        if (!node || !node.audio)
            return;
        const current = node.audio.muted ? 0 : node.audio.volume;
        applyVolume(node, Math.max(0, Math.min(1, current + direction * 0.05)));
    }
}
