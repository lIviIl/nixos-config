pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wi-Fi state shared by the bar and the Connect tab.
// `nmcli monitor` reports changes as they happen, so nothing waits for a poll.
Singleton {
    id: root

    property string ssid: ""
    property real signal: 0
    property bool radioOn: true
    readonly property bool connected: ssid !== ""

    function refresh() {
        if (!query.running)
            query.running = true;
    }

    Process {
        id: query
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f IN-USE,SIGNAL,SSID dev wifi list --rescan no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                root.radioOn = lines[0].trim() === "enabled";
                let ssid = "";
                let signal = 0;
                for (let i = 1; i < lines.length; i++) {
                    if (lines[i] === "")
                        continue;
                    const f = Fmt.splitTerse(lines[i]);
                    if (f[0] === "*") {
                        signal = Number(f[1]) / 100;
                        ssid = f[2];
                        break;
                    }
                }
                root.ssid = ssid;
                root.signal = signal;
            }
        }
    }

    Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: data => settle.restart()
        }
    }

    Timer {
        id: settle
        interval: 600
        onTriggered: root.refresh()
    }

    // Safety net in case an event is missed
    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
