import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Row {
    id: root
    spacing: 14

    component Divider: Rectangle {
        width: 1
        height: 16
        color: Theme.alpha(Theme.gold, 0.45)
    }

    // ---- Volume ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    PwObjectTracker {
        objects: [root.sink]
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

    // ---- Keyboard layout ----
    property string layoutName: "US"

    function shortName(name) {
        const m = name.match(/\(([^)]+)\)/);
        return (m ? m[1] : name.slice(0, 2)).toUpperCase();
    }

    Process {
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(this.text).keyboards;
                    const kb = keyboards.find(k => k.main) || keyboards[0];
                    if (kb)
                        root.layoutName = root.shortName(kb.active_keymap);
                } catch (e) {
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activelayout") {
                const d = event.data;
                root.layoutName = root.shortName(d.slice(d.lastIndexOf(",") + 1));
            }
        }
    }

    // ---- Battery ----
    readonly property var battery: UPower.displayDevice
    readonly property real batteryPct: battery.percentage > 1 ? battery.percentage : battery.percentage * 100
    readonly property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property bool plugged: battery.state === UPowerDeviceState.FullyCharged
    readonly property bool low: batteryPct <= 15 && !charging && !plugged

    StatusItem {
        kind: "volume"
        text: root.muted ? "MUTE" : Math.round(root.volume * 100) + "%"
        level: root.volume
        muted: root.muted

        // Click opens the volume panel; scroll changes the volume
        onClicked: Ui.volumeOpen = !Ui.volumeOpen
        onScrolled: direction => Quickshell.execDetached(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", direction > 0 ? "5%+" : "5%-"])
    }

    Divider { anchors.verticalCenter: parent.verticalCenter }

    StatusItem {
        kind: "wifi"
        text: root.ssid
        level: root.ssid === "offline" ? 0 : 1
    }

    Divider { anchors.verticalCenter: parent.verticalCenter }

    StatusItem {
        kind: "keyboard"
        text: root.layoutName
    }

    Divider { anchors.verticalCenter: parent.verticalCenter }

    StatusItem {
        kind: "battery"
        text: Math.round(root.batteryPct) + "%"
        level: root.batteryPct / 100
        charging: root.charging
        tint: root.low ? Theme.crimson : Theme.fg
    }
}
