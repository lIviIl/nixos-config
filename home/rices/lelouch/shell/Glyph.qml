import QtQuick

// The one icon set, drawn with Canvas so it follows the theme exactly.
// kind: speaker, apps, mic, micOff, sun, bolt, balance, leaf, eye, lock, moon, logout, reboot, power,
//       wifi, bluetooth, headphones, play, pause, next, prev, note, clock, battery, keyboard
// level 0..1: speaker arcs, wifi arcs, battery charge.  muted: speaker.  charging: battery.
// hours/minutes: the clock's hands.
Canvas {
    id: glyph

    property string kind: ""
    property color tint: Theme.fg
    property real level: 1.0
    property bool muted: false
    property bool charging: false
    property int hours: 0
    property int minutes: 0

    width: 18
    height: 18
    renderStrategy: Canvas.Cooperative

    onTintChanged: requestPaint()
    onKindChanged: requestPaint()
    onLevelChanged: requestPaint()
    onMutedChanged: requestPaint()
    onChargingChanged: requestPaint()
    onHoursChanged: requestPaint()
    onMinutesChanged: requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.globalAlpha = 1.0;
        ctx.strokeStyle = tint;
        ctx.fillStyle = tint;
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "miter";
        ctx.lineCap = "butt";

        if (kind === "speaker") {
            ctx.beginPath();
            ctx.moveTo(2, 7);
            ctx.lineTo(5.5, 7);
            ctx.lineTo(9.5, 3.8);
            ctx.lineTo(9.5, 14.2);
            ctx.lineTo(5.5, 11);
            ctx.lineTo(2, 11);
            ctx.closePath();
            ctx.fill();
            if (muted || level <= 0.005) {
                ctx.beginPath();
                ctx.moveTo(11.5, 6.5);
                ctx.lineTo(16.5, 11.5);
                ctx.moveTo(16.5, 6.5);
                ctx.lineTo(11.5, 11.5);
                ctx.stroke();
            } else {
                const radii = [3, 5.5, 8];
                const need = [0.005, 0.34, 0.67];
                for (let i = 0; i < radii.length; i++) {
                    if (level > need[i]) {
                        ctx.beginPath();
                        ctx.arc(9.5, 9, radii[i], -0.9, 0.9);
                        ctx.stroke();
                    }
                }
            }
        } else if (kind === "apps") {
            ctx.fillRect(2, 2, 6, 6);
            ctx.fillRect(10, 2, 6, 6);
            ctx.fillRect(2, 10, 6, 6);
            ctx.fillRect(10, 10, 6, 6);
        } else if (kind === "mic" || kind === "micOff") {
            ctx.beginPath();
            ctx.moveTo(6.5, 5);
            ctx.arc(9, 5, 2.5, Math.PI, 0);
            ctx.lineTo(11.5, 9);
            ctx.arc(9, 9, 2.5, 0, Math.PI);
            ctx.closePath();
            if (kind === "micOff")
                ctx.stroke();
            else
                ctx.fill();
            ctx.beginPath();
            ctx.arc(9, 9, 5.5, 0, Math.PI);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(9, 14.5);
            ctx.lineTo(9, 16.5);
            ctx.moveTo(6.5, 16.5);
            ctx.lineTo(11.5, 16.5);
            ctx.stroke();
            if (kind === "micOff") {
                ctx.beginPath();
                ctx.moveTo(3, 15);
                ctx.lineTo(15, 3);
                ctx.stroke();
            }
        } else if (kind === "sun") {
            ctx.beginPath();
            ctx.arc(9, 9, 3.2, 0, Math.PI * 2);
            ctx.fill();
            for (let i = 0; i < 8; i++) {
                const a = i * Math.PI / 4;
                ctx.beginPath();
                ctx.moveTo(9 + Math.cos(a) * 5.6, 9 + Math.sin(a) * 5.6);
                ctx.lineTo(9 + Math.cos(a) * 8, 9 + Math.sin(a) * 8);
                ctx.stroke();
            }
        } else if (kind === "bolt") {
            ctx.beginPath();
            ctx.moveTo(10, 1.5);
            ctx.lineTo(4.5, 10);
            ctx.lineTo(8.5, 10);
            ctx.lineTo(7.5, 16.5);
            ctx.lineTo(13.5, 7.5);
            ctx.lineTo(9.5, 7.5);
            ctx.closePath();
            ctx.fillStyle = tint;
            ctx.fill();
            ctx.strokeStyle = tint;
            ctx.lineWidth = 0.8;
            ctx.stroke();
        } else if (kind === "balance") {
            ctx.beginPath();
            ctx.moveTo(9, 3);
            ctx.lineTo(9, 15);
            ctx.moveTo(6, 15.5);
            ctx.lineTo(12, 15.5);
            ctx.moveTo(3, 5.5);
            ctx.lineTo(15, 5.5);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(4.5, 5.5);
            ctx.lineTo(2, 10.5);
            ctx.lineTo(7, 10.5);
            ctx.closePath();
            ctx.moveTo(13.5, 5.5);
            ctx.lineTo(11, 10.5);
            ctx.lineTo(16, 10.5);
            ctx.closePath();
            ctx.stroke();
        } else if (kind === "leaf") {
            ctx.beginPath();
            ctx.moveTo(3, 15);
            ctx.bezierCurveTo(3, 7, 8, 3, 15, 3);
            ctx.bezierCurveTo(15, 10, 11, 15, 3, 15);
            ctx.closePath();
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(3, 15);
            ctx.lineTo(11, 7);
            ctx.stroke();
        } else if (kind === "eye") {
            ctx.beginPath();
            ctx.moveTo(1.5, 9);
            ctx.quadraticCurveTo(9, 1, 16.5, 9);
            ctx.quadraticCurveTo(9, 17, 1.5, 9);
            ctx.closePath();
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(9, 9, 2.6, 0, Math.PI * 2);
            ctx.fill();
        } else if (kind === "lock") {
            ctx.strokeRect(4.5, 8.5, 9, 7);
            ctx.beginPath();
            ctx.arc(9, 8.5, 3.2, Math.PI, 0);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(9, 12, 1.2, 0, Math.PI * 2);
            ctx.fill();
        } else if (kind === "moon") {
            ctx.beginPath();
            ctx.arc(8.5, 9.5, 6.5, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath();
            ctx.arc(11.5, 7, 5.2, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalCompositeOperation = "source-over";
        } else if (kind === "logout") {
            ctx.beginPath();
            ctx.moveTo(8, 3);
            ctx.lineTo(3, 3);
            ctx.lineTo(3, 15);
            ctx.lineTo(8, 15);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(7, 9);
            ctx.lineTo(15, 9);
            ctx.moveTo(12, 6);
            ctx.lineTo(15, 9);
            ctx.lineTo(12, 12);
            ctx.stroke();
        } else if (kind === "reboot") {
            const end = 4.21;
            ctx.beginPath();
            ctx.arc(9, 9, 5.5, -1.07, end);
            ctx.stroke();
            const px = 9 + 5.5 * Math.cos(end);
            const py = 9 + 5.5 * Math.sin(end);
            const tx = -Math.sin(end);
            const ty = Math.cos(end);
            ctx.beginPath();
            ctx.moveTo(px + tx * 3.2, py + ty * 3.2);
            ctx.lineTo(px - ty * 2.6, py + tx * 2.6);
            ctx.lineTo(px + ty * 2.6, py - tx * 2.6);
            ctx.closePath();
            ctx.fill();
        } else if (kind === "power") {
            ctx.beginPath();
            ctx.arc(9, 9.5, 6, -Math.PI / 2 + 0.6, -Math.PI / 2 - 0.6 + Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(9, 2);
            ctx.lineTo(9, 9);
            ctx.stroke();
        } else if (kind === "wifi") {
            const radii = [4.5, 8, 11.5];
            const need = [0.05, 0.4, 0.7];
            for (let i = 0; i < radii.length; i++) {
                ctx.globalAlpha = level >= need[i] ? 1.0 : 0.28;
                ctx.beginPath();
                ctx.arc(9, 15, radii[i], -2.36, -0.78);
                ctx.stroke();
            }
            ctx.globalAlpha = 1.0;
            ctx.beginPath();
            ctx.arc(9, 15, 1.4, 0, Math.PI * 2);
            ctx.fill();
        } else if (kind === "bluetooth") {
            ctx.beginPath();
            ctx.moveTo(4.5, 5.5);
            ctx.lineTo(12.5, 12.5);
            ctx.lineTo(9, 16);
            ctx.lineTo(9, 2);
            ctx.lineTo(12.5, 5.5);
            ctx.lineTo(4.5, 12.5);
            ctx.stroke();
        } else if (kind === "headphones") {
            ctx.beginPath();
            ctx.arc(9, 10, 6, Math.PI, 0);
            ctx.stroke();
            ctx.fillRect(2.5, 9.5, 3, 5.5);
            ctx.fillRect(12.5, 9.5, 3, 5.5);
        } else if (kind === "play") {
            ctx.beginPath();
            ctx.moveTo(4.5, 3);
            ctx.lineTo(14.5, 9);
            ctx.lineTo(4.5, 15);
            ctx.closePath();
            ctx.fill();
        } else if (kind === "pause") {
            ctx.fillRect(4.5, 3, 3.5, 12);
            ctx.fillRect(10, 3, 3.5, 12);
        } else if (kind === "next") {
            ctx.beginPath();
            ctx.moveTo(3, 3);
            ctx.lineTo(11, 9);
            ctx.lineTo(3, 15);
            ctx.closePath();
            ctx.fill();
            ctx.fillRect(12.5, 3, 2.5, 12);
        } else if (kind === "prev") {
            ctx.beginPath();
            ctx.moveTo(15, 3);
            ctx.lineTo(7, 9);
            ctx.lineTo(15, 15);
            ctx.closePath();
            ctx.fill();
            ctx.fillRect(3, 3, 2.5, 12);
        } else if (kind === "note") {
            ctx.beginPath();
            ctx.arc(6.2, 13.3, 2.6, 0, Math.PI * 2);
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(8.8, 13.3);
            ctx.lineTo(8.8, 3.2);
            ctx.lineTo(14.5, 5);
            ctx.lineTo(14.5, 8);
            ctx.lineTo(8.8, 6.2);
            ctx.stroke();
        } else if (kind === "clock") {
            ctx.beginPath();
            ctx.arc(9, 9, 7, 0, Math.PI * 2);
            ctx.stroke();
            const m = minutes / 60;
            const h = ((hours % 12) + m) / 12;
            const ha = h * Math.PI * 2 - Math.PI / 2;
            const ma = m * Math.PI * 2 - Math.PI / 2;
            ctx.beginPath();
            ctx.moveTo(9, 9);
            ctx.lineTo(9 + Math.cos(ha) * 3.6, 9 + Math.sin(ha) * 3.6);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(9, 9);
            ctx.lineTo(9 + Math.cos(ma) * 5.4, 9 + Math.sin(ma) * 5.4);
            ctx.stroke();
        } else if (kind === "battery") {
            ctx.strokeRect(1.5, 5.5, 13, 7);
            ctx.fillRect(15, 7.5, 2, 3);
            ctx.fillRect(3.5, 7.5, Math.max(0, Math.min(1, level)) * 9, 3);
            if (charging) {
                ctx.fillStyle = Theme.gold;
                ctx.beginPath();
                ctx.moveTo(9.8, 3.5);
                ctx.lineTo(6.2, 9.6);
                ctx.lineTo(8.8, 9.6);
                ctx.lineTo(8.0, 14.5);
                ctx.lineTo(11.8, 8.2);
                ctx.lineTo(9.2, 8.2);
                ctx.closePath();
                ctx.fill();
            }
        } else if (kind === "bell") {
            ctx.beginPath();
            ctx.moveTo(9, 2.5);
            ctx.bezierCurveTo(5.5, 2.5, 4.5, 5.5, 4.5, 8.5);
            ctx.lineTo(4.5, 11.5);
            ctx.lineTo(3, 13);
            ctx.lineTo(15, 13);
            ctx.lineTo(13.5, 11.5);
            ctx.lineTo(13.5, 8.5);
            ctx.bezierCurveTo(13.5, 5.5, 12.5, 2.5, 9, 2.5);
            ctx.closePath();
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(9, 14.6, 1.6, 0, Math.PI);
            ctx.fill();
        } else if (kind === "calendar") {
            ctx.strokeRect(2.5, 4, 13, 11.5);
            ctx.fillRect(2.5, 4, 13, 3.4);
            ctx.fillRect(5.5, 2, 1.6, 3.6);
            ctx.fillRect(10.9, 2, 1.6, 3.6);
            ctx.fillRect(5, 9.5, 2, 2);
            ctx.fillRect(8, 9.5, 2, 2);
            ctx.fillRect(11, 9.5, 2, 2);
            ctx.fillRect(5, 12.4, 2, 1.8);
            ctx.fillRect(8, 12.4, 2, 1.8);
        } else if (kind === "list") {
            ctx.fillRect(2.5, 4, 2, 2);
            ctx.fillRect(2.5, 8, 2, 2);
            ctx.fillRect(2.5, 12, 2, 2);
            ctx.fillRect(6.5, 4.4, 9, 1.2);
            ctx.fillRect(6.5, 8.4, 9, 1.2);
            ctx.fillRect(6.5, 12.4, 9, 1.2);
        } else if (kind === "check") {
            ctx.strokeRect(2.5, 2.5, 13, 13);
            ctx.beginPath();
            ctx.moveTo(5.5, 9.5);
            ctx.lineTo(8, 12);
            ctx.lineTo(13, 6);
            ctx.stroke();
        } else if (kind === "timer") {
            ctx.beginPath();
            ctx.arc(9, 10.2, 6, 0, Math.PI * 2);
            ctx.stroke();
            ctx.fillRect(7.2, 1.4, 3.6, 2);
            ctx.beginPath();
            ctx.moveTo(9, 10.2);
            ctx.lineTo(9, 6.6);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(14, 4.4);
            ctx.lineTo(15.4, 5.8);
            ctx.stroke();
        } else if (kind === "pencil") {
            ctx.beginPath();
            ctx.moveTo(3, 15);
            ctx.lineTo(3.8, 11.4);
            ctx.lineTo(12, 3.2);
            ctx.lineTo(14.8, 6);
            ctx.lineTo(6.6, 14.2);
            ctx.closePath();
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(10.6, 4.6);
            ctx.lineTo(13.4, 7.4);
            ctx.stroke();
        } else if (kind === "keyboard") {
            ctx.strokeRect(1.5, 4.5, 15, 9);
            ctx.fillRect(4, 6.8, 2, 1.8);
            ctx.fillRect(8, 6.8, 2, 1.8);
            ctx.fillRect(12, 6.8, 2, 1.8);
            ctx.fillRect(5, 10.2, 8, 1.6);
        }
    }
}
