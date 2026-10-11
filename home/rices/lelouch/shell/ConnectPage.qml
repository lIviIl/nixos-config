import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Item {
    id: page

    implicitHeight: layout.implicitHeight

    // ---------------- Wi-Fi ----------------
    property var networks: []
    property var knownNames: []
    property string asking: ""          // the network waiting for a password
    property string wifiMessage: ""

    function refreshWifi() {
        if (!listProc.running)
            listProc.running = true;
        if (!knownProc.running)
            knownProc.running = true;
        Net.refresh();
    }

    function wifiConnect(ssid, password) {
        wifiMessage = "Connecting to " + ssid + "...";
        wifiAction.command = password !== "" ? ["nmcli", "dev", "wifi", "connect", ssid, "password", password] : ["nmcli", "dev", "wifi", "connect", ssid];
        wifiAction.running = true;
    }

    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const names = [];
                const lines = this.text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i] === "")
                        continue;
                    const f = Fmt.splitTerse(lines[i]);
                    if (f[1] === "802-11-wireless" || f[1] === "wifi")
                        names.push(f[0]);
                }
                page.knownNames = names;
            }
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const best = {};
                const lines = this.text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i] === "")
                        continue;
                    const f = Fmt.splitTerse(lines[i]);
                    const ssid = f[1];
                    if (!ssid)
                        continue;
                    const n = {
                        ssid: ssid,
                        signal: Number(f[2]) / 100,
                        secured: f[3] !== "" && f[3] !== "--",
                        inUse: f[0] === "*"
                    };
                    const old = best[ssid];
                    if (!old || n.inUse || (!old.inUse && n.signal > old.signal))
                        best[ssid] = n;
                }
                const list = Object.keys(best).map(k => best[k]);
                list.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
                page.networks = list;
            }
        }
    }

    // Runs a connect command and reports how it went
    Process {
        id: wifiAction
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t !== "")
                    page.wifiMessage = t.split("\n").pop();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t !== "")
                    page.wifiMessage = t.split("\n").pop();
            }
        }
        onExited: page.refreshWifi()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: page.refreshWifi()
    }

    Timer {
        id: afterAction
        interval: 2500
        onTriggered: page.refreshWifi()
    }

    // ---------------- Bluetooth ----------------
    readonly property var adapter: Bluetooth.defaultAdapter

    // Paired and connected devices, plus nearby named ones while scanning
    readonly property var btDevices: {
        if (!adapter)
            return [];
        const list = Array.from(adapter.devices.values).filter(d => d.paired || d.connected || d.bonded || (adapter.discovering && /[A-Za-z]/.test(d.name) && !/^([0-9A-Fa-f]{2}[-:]){5}/.test(d.name)));
        list.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
        return list;
    }

    // Audio profiles of connected Bluetooth devices, from pactl
    property var btCards: ({})

    Process {
        id: cardProc
        command: ["pactl", "--format=json", "list", "cards"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                try {
                    const cards = JSON.parse(this.text);
                    for (let i = 0; i < cards.length; i++) {
                        const c = cards[i];
                        if (!c.name || c.name.indexOf("bluez_card.") !== 0)
                            continue;
                        const list = [];
                        for (const key in c.profiles) {
                            if (key === "off")
                                continue;
                            const p = c.profiles[key];
                            if (p.available === false)
                                continue;
                            list.push({ name: key, priority: p.priority || 0 });
                        }
                        list.sort((a, b) => b.priority - a.priority);
                        out[c.name] = { active: c.active_profile, profiles: list };
                    }
                } catch (e) {
                }
                page.btCards = out;
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!cardProc.running)
                cardProc.running = true;
        }
    }

    Timer {
        id: afterProfile
        interval: 1200
        onTriggered: cardProc.running = true
    }

    // Stop scanning when the tab is left
    Component.onDestruction: {
        if (page.adapter && page.adapter.discovering)
            page.adapter.discovering = false;
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 12

        // ---------------- NETWORK ----------------
        SectionCard {
            icon: "wifi"
            title: "NETWORK"
            subtitle: !Net.radioOn ? "off" : (Net.connected ? Net.ssid : "not connected")

            ToggleRow {
                icon: "wifi"
                label: "Wi-Fi"
                hint: Net.radioOn ? "On" : "Off"
                checked: Net.radioOn
                onToggled: {
                    Quickshell.execDetached(["nmcli", "radio", "wifi", Net.radioOn ? "off" : "on"]);
                    afterAction.restart();
                }
            }

            Text {
                visible: page.wifiMessage !== ""
                Layout.fillWidth: true
                text: page.wifiMessage
                color: Theme.gold
                font.family: Theme.mono
                font.pixelSize: 11
                wrapMode: Text.Wrap
            }

            Text {
                visible: Net.radioOn && page.networks.length === 0
                Layout.fillWidth: true
                text: "No networks found"
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 12
            }

            // About six networks fit; the rest scroll
            Scroller {
                visible: Net.radioOn && page.networks.length > 0
                maxHeight: 250

                Repeater {
                    model: Net.radioOn ? page.networks : []

                    WifiRow {
                        required property var modelData

                        width: parent.width
                        network: modelData
                        known: page.knownNames.indexOf(modelData.ssid) >= 0
                        asking: page.asking === modelData.ssid

                        onActivated: {
                            if (modelData.inUse) {
                                page.wifiMessage = "";
                                Quickshell.execDetached(["nmcli", "connection", "down", "id", modelData.ssid]);
                                afterAction.restart();
                            } else if (known || !modelData.secured) {
                                page.wifiConnect(modelData.ssid, "");
                            } else {
                                page.asking = modelData.ssid;
                            }
                        }

                        onPasswordEntered: password => {
                            page.wifiConnect(modelData.ssid, password);
                            page.asking = "";
                        }

                        onCancelled: page.asking = ""
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 34

                ActionButton {
                    icon: "reboot"
                    label: "RESCAN"
                    enabled: Net.radioOn
                    onClicked: {
                        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
                        afterAction.restart();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    visible: Net.radioOn && page.networks.length > 0
                    text: page.networks.length + " networks"
                    color: Theme.alpha(Theme.fg, 0.65)
                    font.family: Theme.mono
                    font.pixelSize: 11
                }
            }
        }

        // ---------------- BLUETOOTH ----------------
        SectionCard {
            icon: "bluetooth"
            title: "BLUETOOTH"
            subtitle: !page.adapter ? "" : (page.adapter.enabled ? page.btDevices.filter(d => d.connected).length + " connected" : "off")

            Text {
                visible: !page.adapter
                Layout.fillWidth: true
                text: "No Bluetooth adapter found"
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 12
            }

            ToggleRow {
                visible: !!page.adapter
                icon: "bluetooth"
                label: "Bluetooth"
                hint: !!page.adapter && page.adapter.enabled ? "On" : "Off"
                checked: !!page.adapter && page.adapter.enabled
                onToggled: page.adapter.enabled = !page.adapter.enabled
            }

            ToggleRow {
                visible: !!page.adapter
                icon: "reboot"
                label: "Scan for devices"
                hint: "Put the device in pairing mode first"
                checked: !!page.adapter && page.adapter.discovering
                enabled: !!page.adapter && page.adapter.enabled
                onToggled: page.adapter.discovering = !page.adapter.discovering
            }

            // Two or three devices fit; the rest scroll
            Scroller {
                visible: page.btDevices.length > 0
                maxHeight: 250

                Repeater {
                    model: page.btDevices

                    DeviceRow {
                        id: devRow

                        required property var modelData

                        readonly property string cardName: "bluez_card." + modelData.address.replace(/:/g, "_")

                        width: parent.width
                        device: modelData
                        card: page.btCards[cardName] ?? null

                        onProfileChosen: name => {
                            Quickshell.execDetached(["pactl", "set-card-profile", devRow.cardName, name]);
                            afterProfile.restart();
                        }
                    }
                }
            }
        }
    }
}
