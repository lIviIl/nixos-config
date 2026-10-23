import QtQuick
import Quickshell
import Quickshell.Io

// The installed desktops, each with its own rice. Pick another one and confirm: this session ends, the login starts
// the chosen desktop straight away, and it is locked on arrival (see `switch-session` in home/sessions.nix).
Item {
    id: root

    property var sessions: []
    property string note: ""

    readonly property string current: (Identity.desktop || "").toLowerCase()

    implicitWidth: Math.max(row.implicitWidth, hint.implicitWidth)
    implicitHeight: 52

    function choose(id) {
        if (!/^[A-Za-z0-9._-]+$/.test(id) || id === current)
            return;
        note = "Restarting into " + id + "...";
        Quickshell.execDetached(["switch-session", "--relock", id]);
    }

    Process {
        running: true
        command: ["sh", "-c", "for f in /etc/lelouch/wayland-sessions/*.desktop; do basename \"$f\" .desktop; done"]

        stdout: StdioCollector {
            onStreamFinished: root.sessions = this.text.split("\n").filter(s => s !== "" && s !== "lelouch")
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
                active: modelData === root.current
                needsConfirm: modelData !== root.current
                onClicked: root.choose(modelData)
            }
        }
    }

    Text {
        id: hint
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: root.note !== "" ? root.note : "Switching restarts the computer"
        color: Theme.alpha(Theme.fg, 0.7)
        font.family: Theme.mono
        font.pixelSize: 11
    }
}
