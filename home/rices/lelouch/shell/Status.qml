import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Row {
    id: root
    spacing: 8

    // ---- Volume ----
    readonly property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: [root.sink]
    }

    readonly property string volumeText: {
        if (!sink || !sink.audio)
            return "VOL --";
        if (sink.audio.muted)
            return "MUTED";
        return "VOL " + Math.round(sink.audio.volume * 100) + "%";
    }

    // ---- Wi-Fi ----
    property string ssid: "offline"

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.split("\n").find(l => l.startsWith("yes:"));
                root.ssid = line ? line.slice(4) : "offline";
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiProc.running = true
    }

    // ---- Battery ----
    readonly property var battery: UPower.displayDevice
    readonly property real batteryPct: battery.percentage > 1 ? battery.percentage : battery.percentage * 100
    readonly property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property bool plugged: battery.state === UPowerDeviceState.FullyCharged
    readonly property bool low: batteryPct <= 15 && !charging && !plugged

    readonly property string batteryText: (charging ? "CHG " : plugged ? "AC " : "BAT ") + Math.round(batteryPct) + "%"

    Pill {
        BarText { text: root.volumeText }
    }

    Pill {
        BarText { text: root.ssid }
    }

    Pill {
        borderColor: root.low ? Theme.danger : Theme.alpha(Theme.gold, 0.8)

        BarText {
            text: root.batteryText
            color: root.low ? Theme.danger : Theme.fg
        }
    }
}
