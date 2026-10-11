import QtQuick
import Quickshell
import Quickshell.Io

// A real-time spectrum from cava, drawn as bars. cava only runs while active is true.
Item {
    id: viz

    property bool active: false
    property var levels: []

    onLevelsChanged: spectrum.requestPaint()

    Process {
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/lelouch-cava/config"]
        running: viz.active

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(";");
                const values = [];
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i] !== "")
                        values.push(Number(parts[i]));
                }
                viz.levels = values;
            }
        }
    }

    Canvas {
        id: spectrum
        anchors.fill: parent

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            const n = 32;
            const gap = 3;
            const w = (width - gap * (n - 1)) / n;

            for (let i = 0; i < n; i++) {
                const level = viz.active && i < viz.levels.length ? viz.levels[i] : 0;
                const h = Math.max(2, level / 100 * (height - 4));
                ctx.fillStyle = Theme.mix(Theme.primary, Theme.gold, i / (n - 1));
                ctx.fillRect(i * (w + gap), height - h, w, h);
            }
        }
    }
}
