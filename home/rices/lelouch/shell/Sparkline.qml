import QtQuick

// A filled line graph of the most recent values (newest on the right). Up to two series.
Canvas {
    id: graph

    property var values: []
    property var values2: []
    property real maxValue: 100        // 0 = scale to the data
    property color lineColor: Theme.primary
    property color lineColor2: Theme.crimson
    property int samples: 60

    onValuesChanged: requestPaint()
    onValues2Changed: requestPaint()
    onLineColorChanged: requestPaint()
    onLineColor2Changed: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function yFor(v, top) {
        return height - Math.min(1, v / top) * (height - 3) - 1;
    }

    function draw(ctx, series, stroke, top) {
        if (series.length < 2)
            return;
        const step = width / (samples - 1);
        const x0 = width - (series.length - 1) * step;

        ctx.beginPath();
        ctx.moveTo(x0, height);
        for (let i = 0; i < series.length; i++)
            ctx.lineTo(x0 + i * step, yFor(series[i], top));
        ctx.lineTo(width, height);
        ctx.closePath();
        ctx.fillStyle = Theme.alpha(stroke, 0.2);
        ctx.fill();

        ctx.beginPath();
        for (let i = 0; i < series.length; i++) {
            if (i === 0)
                ctx.moveTo(x0, yFor(series[i], top));
            else
                ctx.lineTo(x0 + i * step, yFor(series[i], top));
        }
        ctx.strokeStyle = stroke;
        ctx.lineWidth = 1.6;
        ctx.stroke();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        ctx.strokeStyle = Theme.alpha(Theme.fg, 0.1);
        ctx.lineWidth = 1;
        for (let g = 1; g < 4; g++) {
            const y = Math.round(height * g / 4) + 0.5;
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
            ctx.stroke();
        }

        let top = maxValue;
        if (top <= 0) {
            top = 1;
            for (let i = 0; i < values.length; i++)
                top = Math.max(top, values[i]);
            for (let i = 0; i < values2.length; i++)
                top = Math.max(top, values2[i]);
            top *= 1.15;
        }

        draw(ctx, values, lineColor, top);
        draw(ctx, values2, lineColor2, top);
    }
}
