import QtQuick

// Small geometric icons drawn with Canvas, so they follow the theme exactly.
// kind: clock, battery, volume, wifi, keyboard
Canvas {
    id: icon

    property string kind: "clock"
    property color tint: Theme.fg
    property real level: 1.0
    property bool muted: false
    property bool charging: false
    property int hours: 0
    property int minutes: 0

    width: 18
    height: 18

    onTintChanged: requestPaint()
    onKindChanged: requestPaint()
    onLevelChanged: requestPaint()
    onMutedChanged: requestPaint()
    onChargingChanged: requestPaint()
    onHoursChanged: requestPaint()
    onMinutesChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.strokeStyle = tint;
        ctx.fillStyle = tint;
        ctx.lineWidth = 1.5;
        ctx.lineJoin = "miter";
        ctx.lineCap = "butt";

        if (kind === "clock") {
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
        } else if (kind === "volume") {
            ctx.beginPath();
            ctx.moveTo(2, 7);
            ctx.lineTo(5.5, 7);
            ctx.lineTo(9.5, 3.8);
            ctx.lineTo(9.5, 14.2);
            ctx.lineTo(5.5, 11);
            ctx.lineTo(2, 11);
            ctx.closePath();
            ctx.fill();

            if (muted) {
                ctx.beginPath();
                ctx.moveTo(12.5, 6.5);
                ctx.lineTo(16.5, 11.5);
                ctx.moveTo(16.5, 6.5);
                ctx.lineTo(12.5, 11.5);
                ctx.stroke();
            } else {
                if (level > 0.01) {
                    ctx.beginPath();
                    ctx.arc(9.5, 9, 3.6, -0.9, 0.9);
                    ctx.stroke();
                }
                if (level > 0.5) {
                    ctx.beginPath();
                    ctx.arc(9.5, 9, 6.6, -0.9, 0.9);
                    ctx.stroke();
                }
            }
        } else if (kind === "wifi") {
            ctx.globalAlpha = level > 0 ? 1.0 : 0.35;
            const radii = [4.5, 8, 11.5];
            for (let i = 0; i < radii.length; i++) {
                ctx.beginPath();
                ctx.arc(9, 14.5, radii[i], -2.36, -0.78);
                ctx.stroke();
            }
            ctx.beginPath();
            ctx.arc(9, 14.5, 1.4, 0, Math.PI * 2);
            ctx.fill();
        } else if (kind === "keyboard") {
            ctx.strokeRect(1.5, 4.5, 15, 9);
            ctx.fillRect(4, 6.8, 2, 1.8);
            ctx.fillRect(8, 6.8, 2, 1.8);
            ctx.fillRect(12, 6.8, 2, 1.8);
            ctx.fillRect(5, 10.2, 8, 1.6);
        }
    }
}
