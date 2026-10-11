import QtQuick
import Quickshell
import Quickshell.Io

// The installed desktop sessions. Your choice is remembered for the next login
// (it takes effect once modules/nixos/session-switcher.nix is enabled).
Item {
    id: root

    property var sessions: []
    property string chosen: ""
    property string note: ""

    readonly property string current: (Identity.desktop || "").toLowerCase()

    implicitWidth: row.implicitWidth
    implicitHeight: 52

    function choose(id) {
        if (!/^[A-Za-z0-9._-]+$/.test(id))
            return;
        chosen = id;
        note = id === current ? "" : "Next login: " + id;
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.config/lelouch\" && printf '%s\\n' \"$1\" > \"$HOME/.config/lelouch/session\"", "sh", id]);
    }

    Process {
        command: ["sh", "-c", "ls /run/current-system/sw/share/wayland-sessions /run/current-system/sw/share/xsessions 2>/dev/null; echo ---; cat \"$HOME/.config/lelouch/session\" 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.split("---");
                const found = [];
                const seen = {};
                const lines = parts[0].split("\n");
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].endsWith(".desktop")) {
                        const id = lines[i].slice(0, -8);
                        if (!seen[id]) {
                            seen[id] = true;
                            found.push(id);
                        }
                    }
                }
                root.sessions = found;
                root.chosen = (parts[1] || "").trim();
            }
        }
    }

    Row {
        id: row
        anchors.right: parent.right
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "SESSION"
            color: Theme.gold
            font.family: Theme.mono
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 3
        }

        Repeater {
            model: root.sessions

            ActionButton {
                required property string modelData

                label: modelData.toUpperCase()
                active: modelData === (root.chosen !== "" ? root.chosen : root.current)
                onClicked: root.choose(modelData)
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.note !== ""
        text: root.note
        color: Theme.alpha(Theme.fg, 0.75)
        font.family: Theme.mono
        font.pixelSize: 11
    }
}
