import QtQuick

// Small geometric icons drawn with Canvas, so they follow the theme exactly.
// kind: speaker, apps, mic, micOff, sun, bolt, balance, leaf, eye, lock, moon, logout, reboot, power
Canvas {
    id: glyph

    property string kind: ""
    property color tint: Theme.fg

    width: 18
    height: 18

    onTintChanged: requestPaint()
    onKindChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
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
            ctx.beginPath();
            ctx.arc(9.5, 9, 3.6, -0.9, 0.9);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(9.5, 9, 6.6, -0.9, 0.9);
            ctx.stroke();
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
            ctx.fill();
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
        }
    }
}
