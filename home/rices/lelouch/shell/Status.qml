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

    Timer {
        id: radioDelay
        interval: 800
        onTriggered: Net.refresh()
    }

    // Left click: volume panel.  Right click: the Controls tab.  Scroll: change the volume.
    StatusItem {
        kind: "volume"
        text: root.muted ? "MUTE" : Math.round(root.volume * 100) + "%"
        level: root.volume
        muted: root.muted

        onClicked: Ui.volumeOpen = !Ui.volumeOpen
        onRightClicked: Ui.toggleCenter("controls")
        onScrolled: direction => Quickshell.execDetached(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", direction > 0 ? "5%+" : "5%-"])
    }

    Divider { anchors.verticalCenter: parent.verticalCenter }

    // Left click: the Connect tab.  Right click: Wi-Fi on or off.
    StatusItem {
        kind: "wifi"
        text: !Net.radioOn ? "off" : (Net.connected ? Net.ssid : "offline")
        level: Net.connected ? Net.signal : 0

        onClicked: Ui.toggleCenter("connect")
        onRightClicked: {
            Quickshell.execDetached(["nmcli", "radio", "wifi", Net.radioOn ? "off" : "on"]);
            radioDelay.restart();
        }
    }

    Divider { anchors.verticalCenter: parent.verticalCenter }

    // Click: next keyboard layout
    StatusItem {
        kind: "keyboard"
        text: root.layoutName

        onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    }

    Divider { anchors.verticalCenter: parent.verticalCenter }

    // Left click: the System tab.  Right click: power profiles.
    StatusItem {
        kind: "battery"
        text: Math.round(root.batteryPct) + "%"
        level: root.batteryPct / 100
        charging: root.charging
        tint: root.low ? Theme.crimson : Theme.fg

        onClicked: Ui.toggleCenter("system")
        onRightClicked: Ui.toggleCenter("controls")
    }
}
