import QtQuick
import QtQuick.Layouts

Item {
    id: page

    implicitHeight: layout.implicitHeight

    readonly property color accent: Focus.mode === "pomodoro" && Focus.phase !== "work" ? Theme.gold : Theme.primary
    readonly property string shownText: Fmt.hms(Focus.countdown ? Math.ceil(Focus.shown / 1000) : Math.floor(Focus.shown / 1000))

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
            title: Focus.title
            subtitle: Focus.phaseLabel

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 220
                Layout.preferredHeight: 220

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
                        text: page.shownText
                        color: Theme.fg
                        font.family: Theme.serif
                        font.weight: Font.Light
                        font.pixelSize: 44
                        font.letterSpacing: 2
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Focus.running ? (Focus.phaseLabel !== "" ? Focus.phaseLabel : "RUNNING") : (Focus.active ? "PAUSED" : "READY")
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

            DurationField {
                visible: Focus.mode === "pomodoro"
                label: "FOCUS"
                seconds: Focus.workSec
                onEdited: s => Focus.setLength("work", s)
            }

            DurationField {
                visible: Focus.mode === "pomodoro"
                label: "SHORT BREAK"
                seconds: Focus.shortSec
                onEdited: s => Focus.setLength("short", s)
            }

            DurationField {
                visible: Focus.mode === "pomodoro"
                label: "LONG BREAK"
                seconds: Focus.longSec
                onEdited: s => Focus.setLength("long", s)
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
                    model: [30, 60, 300, 600, 900, 1800, 3600]

                    ActionButton {
                        required property int modelData

                        label: modelData < 60 ? modelData + " SEC" : (modelData / 60) + " MIN"
                        active: Focus.timerSec === modelData
                        onClicked: Focus.setLength("timer", modelData)
                    }
                }
            }

            DurationField {
                visible: Focus.mode === "timer"
                label: "DURATION"
                seconds: Focus.timerSec
                onEdited: s => Focus.setLength("timer", s)
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

            ToggleRow {
                visible: Focus.mode !== "stopwatch"
                icon: "speaker"
                label: "Sound"
                hint: "Play a chime when a phase ends"
                checked: Focus.sound
                onToggled: Focus.sound = !Focus.sound
            }
        }
    }
}
