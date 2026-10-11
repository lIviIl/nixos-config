import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: page

    // ---------------- Audio ----------------
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Application playback streams: PipeWire's own stream type when it reports one,
    // otherwise Quickshell's direction flag (playback streams count as sinks there)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio && ((n.properties && n.properties["media.class"]) ? n.properties["media.class"] === "Stream/Output/Audio" : n.isSink))

    readonly property var denoised: Pipewire.nodes.values.filter(n => n.name === "rnnoise_source")[0] ?? null
    readonly property var microphone: Pipewire.nodes.values.filter(n => !n.isStream && !n.isSink && n.audio && n.name !== "rnnoise_source")[0] ?? null
    readonly property var mic: microphone ?? source
    readonly property bool denoiseOn: !!source && source.name === "rnnoise_source"

    readonly property real sinkVolume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool sinkMuted: !!sink && !!sink.audio && sink.audio.muted
    readonly property bool micMuted: !!mic && !!mic.audio && mic.audio.muted

    PwObjectTracker {
        objects: [page.sink, page.mic, page.source].filter(n => n).concat(page.streams)
    }

    // The lowest setting mutes; moving up from it unmutes
    function applyVolume(node, v) {
        if (!node || !node.audio)
            return;
        const id = String(node.id);
        if (v <= 0.005) {
            Quickshell.execDetached(["wpctl", "set-volume", id, "0"]);
            if (!node.audio.muted)
                Quickshell.execDetached(["wpctl", "set-mute", id, "1"]);
        } else {
            if (node.audio.muted)
                Quickshell.execDetached(["wpctl", "set-mute", id, "0"]);
            Quickshell.execDetached(["wpctl", "set-volume", id, v.toFixed(2)]);
        }
    }

    function toggleMute(id) {
        Quickshell.execDetached(["wpctl", "set-mute", String(id), "toggle"]);
    }

    // Close the drawer first, then run the command
    function run(args) {
        Ui.centerOpen = false;
        Quickshell.execDetached(["sh", "-c", "sleep 0.5; exec \"$@\"", "sh"].concat(args));
    }

    // ---------------- Brightness ----------------
    property real brightness: 0.5

    Process {
        id: brightRead
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.trim().split(",");
                // Ignore readings for a moment after the slider was used
                if (f.length >= 5 && !holdPoll.running)
                    page.brightness = parseInt(f[3]) / 100;
            }
        }
    }

    Timer {
        id: holdPoll
        interval: 1800
    }

    // ---------------- Power profiles ----------------
    property string profile: ""
    property var profiles: []

    Process {
        id: profGet
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: page.profile = this.text.trim()
        }
    }

    Process {
        id: profList
        command: ["powerprofilesctl", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = [];
                const lines = this.text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const m = lines[i].match(/^[* ]\s*([a-z-]+):/);
                    if (m)
                        names.push(m[1]);
                }
                page.profiles = names;
            }
        }
    }

    function setProfile(name) {
        profile = name;
        Quickshell.execDetached(["powerprofilesctl", "set", name]);
    }

    Component.onCompleted: profList.running = true

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!brightRead.running)
                brightRead.running = true;
            if (!profGet.running)
                profGet.running = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // ---------------- AUDIO OUTPUT ----------------
        SectionCard {
            Layout.preferredHeight: 100
            icon: "speaker"
            iconLevel: page.sinkVolume
            iconMuted: page.sinkMuted
            title: "AUDIO OUTPUT"
            subtitle: page.sinkMuted ? "MUTED" : Math.round(page.sinkVolume * 100) + "%"

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 12

                Slider {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    value: page.sinkVolume
                    onMoved: v => page.applyVolume(page.sink, v)
                }

                ActionButton {
                    Layout.preferredWidth: 92
                    Layout.fillHeight: true
                    label: page.sinkMuted ? "UNMUTE" : "MUTE"
                    active: page.sinkMuted
                    onClicked: page.toggleMute(page.sink.id)
                }
            }
        }

        // ---------------- APPLICATIONS (takes the remaining height) ----------------
        SectionCard {
            Layout.fillHeight: true
            Layout.minimumHeight: 100
            icon: "apps"
            title: "APPLICATIONS"
            subtitle: page.streams.length + " playing"

            Item {
                id: appsArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                readonly property int capacity: Math.max(1, Math.floor(height / 48))

                Text {
                    visible: page.streams.length === 0
                    text: "Nothing is playing sound"
                    color: Theme.alpha(Theme.fg, 0.7)
                    font.family: Theme.mono
                    font.pixelSize: 12
                }

                Column {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: page.streams.slice(0, appsArea.capacity)

                        Column {
                            id: app

                            required property var modelData

                            readonly property string appName: (modelData.properties && modelData.properties["application.name"]) || modelData.nickname || modelData.name

                            width: parent.width
                            spacing: 2

                            Item {
                                width: parent.width
                                height: 18

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 80
                                    elide: Text.ElideRight
                                    text: app.appName
                                    color: Theme.fg
                                    font.family: Theme.mono
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: app.modelData.audio.muted ? "MUTED" : Math.round(app.modelData.audio.volume * 100) + "%"
                                    color: app.modelData.audio.muted ? Theme.crimson : Theme.alpha(Theme.fg, 0.8)
                                    font.family: Theme.mono
                                    font.pixelSize: 12
                                    font.bold: true

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: app.modelData.audio.muted = !app.modelData.audio.muted
                                    }
                                }
                            }

                            Slider {
                                width: parent.width
                                height: 22
                                value: app.modelData.audio.volume
                                onMoved: v => {
                                    app.modelData.audio.volume = v;
                                    app.modelData.audio.muted = v <= 0.005;
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: page.streams.length > appsArea.capacity
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: "+" + (page.streams.length - appsArea.capacity) + " more"
                    color: Theme.gold
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // ---------------- MICROPHONE ----------------
        SectionCard {
            Layout.preferredHeight: 156
            icon: page.micMuted ? "micOff" : "mic"
            title: "MICROPHONE"
            subtitle: page.mic && page.mic.audio ? (page.micMuted ? "MUTED" : "LIVE") : "none"

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 12

                Slider {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    value: page.mic && page.mic.audio ? page.mic.audio.volume : 0
                    onMoved: v => page.applyVolume(page.mic, v)
                }

                ActionButton {
                    Layout.preferredWidth: 92
                    Layout.fillHeight: true
                    label: page.micMuted ? "UNMUTE" : "MUTE"
                    active: page.micMuted
                    danger: page.micMuted
                    onClicked: page.toggleMute(page.mic.id)
                }
            }

            ToggleRow {
                icon: "mic"
                label: "Noise suppression"
                hint: page.denoised === null ? "Virtual microphone not found" : "RNNoise virtual microphone"
                checked: page.denoiseOn
                enabled: page.denoised !== null && page.microphone !== null
                onToggled: Pipewire.preferredDefaultAudioSource = page.denoiseOn ? page.microphone : page.denoised
            }
        }

        // ---------------- DISPLAY ----------------
        SectionCard {
            Layout.preferredHeight: 100
            icon: "sun"
            title: "DISPLAY"
            subtitle: Math.round(page.brightness * 100) + "%"

            Slider {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                value: page.brightness
                onMoved: v => {
                    page.brightness = v;
                    holdPoll.restart();
                    Quickshell.execDetached(["brightnessctl", "-q", "set", Math.max(1, Math.round(v * 100)) + "%"]);
                }
            }
        }

        // ---------------- POWER ----------------
        SectionCard {
            Layout.preferredHeight: 160
            icon: "bolt"
            title: "POWER"
            subtitle: page.profile.replace("-", " ").toUpperCase()

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                spacing: 8

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon: "bolt"
                    label: "PERFORMANCE"
                    active: page.profile === "performance"
                    enabled: page.profiles.indexOf("performance") >= 0
                    onClicked: page.setProfile("performance")
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon: "balance"
                    label: "BALANCED"
                    active: page.profile === "balanced"
                    enabled: page.profiles.indexOf("balanced") >= 0
                    onClicked: page.setProfile("balanced")
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    icon: "leaf"
                    label: "POWER SAVER"
                    active: page.profile === "power-saver"
                    enabled: page.profiles.indexOf("power-saver") >= 0
                    onClicked: page.setProfile("power-saver")
                }
            }

            ToggleRow {
                icon: "eye"
                label: "Idle inhibitor"
                hint: "Block screen lock, blanking and idle suspend"
                checked: Ui.idleInhibit
                onToggled: Ui.idleInhibit = !Ui.idleInhibit
            }
        }

        // ---------------- SESSION ----------------
        SectionCard {
            Layout.preferredHeight: 126
            icon: "power"
            title: "SESSION"

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                spacing: 8

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    vertical: true
                    icon: "lock"
                    label: "LOCK"
                    onClicked: page.run(["lock-screen"])
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    vertical: true
                    icon: "moon"
                    label: "SUSPEND"
                    onClicked: {
                        Ui.centerOpen = false;
                        Quickshell.execDetached(["systemctl", "suspend"]);
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    vertical: true
                    icon: "logout"
                    label: "LOG OUT"
                    danger: true
                    needsConfirm: true
                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    vertical: true
                    icon: "reboot"
                    label: "REBOOT"
                    danger: true
                    needsConfirm: true
                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    vertical: true
                    icon: "power"
                    label: "SHUTDOWN"
                    danger: true
                    needsConfirm: true
                    onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }
    }
}
