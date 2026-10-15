import QtQuick
import QtQuick.Layouts

Item {
    id: page

    implicitHeight: layout.implicitHeight

    readonly property string phaseLabel: Focus.mode === "pomodoro" ? (Focus.phase === "work" ? "FOCUS" : (Focus.phase === "short" ? "SHORT BREAK" : "LONG BREAK")) : (Focus.mode === "timer" ? "TIMER" : "STOPWATCH")
    readonly property color accent: Focus.mode === "pomodoro" && Focus.phase !== "work" ? Theme.gold : Theme.primary

    function pad(n) {
        return (n < 10 ? "0" : "") + n;
    }

    function hms(ms) {
        const s = Focus.countdown ? Math.ceil(ms / 1000) : Math.floor(ms / 1000);
        const h = Math.floor(s / 3600);
        const m = Math.floor(s % 3600 / 60);
        return (h > 0 ? h + ":" + pad(m) : pad(m)) + ":" + pad(s % 60);
    }

    // A label with  < value >  at the right
    component Stepper: Item {
        id: step

        property string label: ""
        property string text: ""

        signal stepped(int delta)

        Layout.fillWidth: true
        Layout.preferredHeight: 34

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: step.label
            color: Theme.alpha(Theme.fg, 0.8)
            font.family: Theme.mono
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            ChevronButton {
                direction: -1
                onClicked: step.stepped(-1)
            }

            Item {
                width: 80
                height: 30

                Text {
                    anchors.centerIn: parent
                    text: step.text
                    color: Theme.fg
                    font.family: Theme.mono
                    font.pixelSize: 13
                    font.bold: true
                }
            }

            ChevronButton {
                direction: 1
                onClicked: step.stepped(1)
            }
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            spacing: 8

            ActionButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                label: "POMODORO"
                active: Focus.mode === "pomodoro"
                onClicked: Focus.setMode("pomodoro")
            }

            ActionButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                label: "TIMER"
                active: Focus.mode === "timer"
                onClicked: Focus.setMode("timer")
            }

            ActionButton {
                Layout.fillWidth: true
                Layout.fillHeight: true
                label: "STOPWATCH"
                active: Focus.mode === "stopwatch"
                onClicked: Focus.setMode("stopwatch")
            }
        }

        // ---------------- The clock ----------------
        SectionCard {
            icon: "timer"
            title: "FOCUS"
            subtitle: page.phaseLabel

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 230
                Layout.preferredHeight: 230

                Canvas {
                    id: ring
                    anchors.fill: parent

                    property real fraction: Focus.fraction
                    property color tint: page.accent

                    onFractionChanged: requestPaint()
                    onTintChanged: requestPaint()
                    Component.onCompleted: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const cx = width / 2;
                        const cy = height / 2;
                        const r = width / 2 - 12;

                        // Twelve ticks around the outside
                        ctx.strokeStyle = Theme.alpha(Theme.gold, 0.6);
                        ctx.lineWidth = 2;
                        for (let i = 0; i < 12; i++) {
                            const a = i * Math.PI / 6;
                            ctx.beginPath();
                            ctx.moveTo(cx + Math.cos(a) * (r + 6), cy + Math.sin(a) * (r + 6));
                            ctx.lineTo(cx + Math.cos(a) * (r + 10), cy + Math.sin(a) * (r + 10));
                            ctx.stroke();
                        }

                        // The track, then the progress
                        ctx.lineCap = "butt";
                        ctx.lineWidth = 7;
                        ctx.strokeStyle = Theme.alpha(Theme.fg, 0.14);
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, Math.PI * 2);
                        ctx.stroke();

                        if (fraction > 0.001) {
                            ctx.strokeStyle = tint;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(1, fraction));
                            ctx.stroke();
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.hms(Focus.shown)
                        color: Theme.fg
                        font.family: Theme.serif
                        font.weight: Font.Light
                        font.pixelSize: 46
                        font.letterSpacing: 2
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Focus.running ? page.phaseLabel : (Focus.active ? "PAUSED" : "READY")
                        color: Focus.running ? page.accent : Theme.alpha(Theme.fg, 0.65)
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 3
                    }
                }
            }

            // Sessions finished in this cycle of four
            Row {
                visible: Focus.mode === "pomodoro"
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Repeater {
                    model: 4

                    Chamfer {
                        required property int index

                        width: 14
                        height: 14
                        cut: 4
                        strokeColor: Theme.gold
                        fillTop: index < Focus.cycleCount ? Theme.gold : "transparent"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 8

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon: Focus.running ? "pause" : "play"
                    label: Focus.running ? "PAUSE" : (Focus.active ? "RESUME" : "START")
                    active: Focus.running
                    onClicked: Focus.toggle()
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon: "reboot"
                    label: "RESET"
                    enabled: Focus.active
                    onClicked: Focus.resetTime()
                }

                ActionButton {
                    visible: Focus.mode === "pomodoro"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon: "next"
                    label: "SKIP"
                    onClicked: Focus.skip()
                }
            }
        }

        // ---------------- Settings ----------------
        SectionCard {
            icon: "list"
            title: "SETTINGS"

            Stepper {
                visible: Focus.mode === "pomodoro"
                label: "FOCUS"
                text: Focus.workMin + " min"
                onStepped: delta => Focus.adjust("work", delta)
            }

            Stepper {
                visible: Focus.mode === "pomodoro"
                label: "SHORT BREAK"
                text: Focus.shortMin + " min"
                onStepped: delta => Focus.adjust("short", delta)
            }

            Stepper {
                visible: Focus.mode === "pomodoro"
                label: "LONG BREAK"
                text: Focus.longMin + " min"
                onStepped: delta => Focus.adjust("long", delta)
            }

            ToggleRow {
                visible: Focus.mode === "pomodoro"
                icon: "timer"
                label: "Auto-start next phase"
                hint: "Sessions and breaks follow each other"
                checked: Focus.autoStart
                onToggled: Focus.autoStart = !Focus.autoStart
            }

            Flow {
                visible: Focus.mode === "timer"
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [5, 10, 15, 30, 60]

                    ActionButton {
                        required property int modelData

                        label: modelData + " MIN"
                        active: Focus.timerMin === modelData
                        onClicked: Focus.setTimerMinutes(modelData)
                    }
                }
            }

            Stepper {
                visible: Focus.mode === "timer"
                label: "DURATION"
                text: Focus.timerMin + " min"
                onStepped: delta => Focus.adjust("timer", delta)
            }

            Text {
                visible: Focus.mode === "stopwatch"
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "The stopwatch counts up. The ring shows the current minute."
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 12
            }
        }
    }
}
