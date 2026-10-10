import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Flickable {
    id: page

    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

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

    PwObjectTracker {
        objects: [page.sink, page.mic, page.source].filter(n => n).concat(page.streams)
    }

    function setVolume(id, v) {
        Quickshell.execDetached(["wpctl", "set-volume", String(id), v.toFixed(2)]);
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
                if (f.length >= 5)
                    page.brightness = parseInt(f[3]) / 100;
            }
        }
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

    Column {
        id: column
        width: page.width
        spacing: 12

        // ---------------- AUDIO OUTPUT ----------------
        SectionCard {
            width: parent.width
            icon: "speaker"
            title: "AUDIO OUTPUT"
            subtitle: page.sink && page.sink.audio ? (page.sink.audio.muted ? "MUTED" : Math.round(page.sink.audio.volume * 100) + "%") : "--"

            Item {
                width: parent.width
                height: 34

                Slider {
                    anchors.left: parent.left
                    anchors.right: muteOutput.left
                    anchors.rightMargin: 12
                    height: parent.height
                    value: page.sink && page.sink.audio ? page.sink.audio.volume : 0
                    onMoved: v => page.setVolume(page.sink.id, v)
                }

                ActionButton {
                    id: muteOutput
                    anchors.right: parent.right
                    width: 92
                    label: page.sink && page.sink.audio && page.sink.audio.muted ? "UNMUTE" : "MUTE"
                    active: page.sink && page.sink.audio && page.sink.audio.muted
                    onClicked: page.toggleMute(page.sink.id)
                }
            }
        }

        // ---------------- APPLICATIONS ----------------
        SectionCard {
            width: parent.width
            icon: "apps"
            title: "APPLICATIONS"
            subtitle: page.streams.length + " playing"

            Text {
                visible: page.streams.length === 0
                text: "Nothing is playing sound"
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 12
            }

            Repeater {
                model: page.streams

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
                        onMoved: v => app.modelData.audio.volume = v
                    }
                }
            }
        }

        // ---------------- MICROPHONE ----------------
        SectionCard {
            width: parent.width
            icon: page.mic && page.mic.audio && page.mic.audio.muted ? "micOff" : "mic"
            title: "MICROPHONE"
            subtitle: page.mic && page.mic.audio ? (page.mic.audio.muted ? "MUTED" : "LIVE") : "none"

            Item {
                width: parent.width
                height: 34

                Slider {
                    anchors.left: parent.left
                    anchors.right: muteMic.left
                    anchors.rightMargin: 12
                    height: parent.height
                    value: page.mic && page.mic.audio ? page.mic.audio.volume : 0
                    onMoved: v => page.setVolume(page.mic.id, v)
                }

                ActionButton {
                    id: muteMic
                    anchors.right: parent.right
                    width: 92
                    label: page.mic && page.mic.audio && page.mic.audio.muted ? "UNMUTE" : "MUTE"
                    active: page.mic && page.mic.audio && page.mic.audio.muted
                    danger: page.mic && page.mic.audio && page.mic.audio.muted
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
            width: parent.width
            icon: "sun"
            title: "DISPLAY"
            subtitle: Math.round(page.brightness * 100) + "%"

            Slider {
                width: parent.width
                height: 28
                value: page.brightness
                onMoved: v => Quickshell.execDetached(["brightnessctl", "-q", "set", Math.max(1, Math.round(v * 100)) + "%"])
            }
        }

        // ---------------- POWER ----------------
        SectionCard {
            width: parent.width
            icon: "bolt"
            title: "POWER"
            subtitle: page.profile.replace("-", " ").toUpperCase()

            Row {
                width: parent.width
                spacing: 8

                ActionButton {
                    width: Math.floor((parent.width - 16) / 3)
                    icon: "bolt"
                    label: "PERFORMANCE"
                    active: page.profile === "performance"
                    enabled: page.profiles.indexOf("performance") >= 0
                    onClicked: page.setProfile("performance")
                }

                ActionButton {
                    width: Math.floor((parent.width - 16) / 3)
                    icon: "balance"
                    label: "BALANCED"
                    active: page.profile === "balanced"
                    enabled: page.profiles.indexOf("balanced") >= 0
                    onClicked: page.setProfile("balanced")
                }

                ActionButton {
                    width: Math.floor((parent.width - 16) / 3)
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
            width: parent.width
            icon: "power"
            title: "SESSION"

            Row {
                width: parent.width
                spacing: 8

                ActionButton {
                    width: Math.floor((parent.width - 32) / 5)
                    vertical: true
                    icon: "lock"
                    label: "LOCK"
                    onClicked: page.run(["lock-screen"])
                }

                ActionButton {
                    width: Math.floor((parent.width - 32) / 5)
                    vertical: true
                    icon: "moon"
                    label: "SUSPEND"
                    onClicked: {
                        Ui.centerOpen = false;
                        Quickshell.execDetached(["systemctl", "suspend"]);
                    }
                }

                ActionButton {
                    width: Math.floor((parent.width - 32) / 5)
                    vertical: true
                    icon: "logout"
                    label: "LOG OUT"
                    danger: true
                    needsConfirm: true
                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
                }

                ActionButton {
                    width: Math.floor((parent.width - 32) / 5)
                    vertical: true
                    icon: "reboot"
                    label: "REBOOT"
                    danger: true
                    needsConfirm: true
                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                }

                ActionButton {
                    width: Math.floor((parent.width - 32) / 5)
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
