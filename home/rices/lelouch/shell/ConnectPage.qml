import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Item {
    id: page

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

    // As many devices as fit in the space (a connected one is taller: it shows its audio profiles)
    function fitDevices(list, h) {
        const out = [];
        let used = 0;
        for (let i = 0; i < list.length; i++) {
            const need = list[i].connected ? 124 : 52;
            if (used + need > h && out.length > 0)
                break;
            out.push(list[i]);
            used += need;
        }
        return out;
    }

    // Audio profiles of connected Bluetooth devices, from pactl
    property var btCards: ({})

    function profileLabel(name) {
        if (name.indexOf("a2dp") === 0)
            return "A2DP";
        if (name.indexOf("headset") === 0)
            return "HANDS-FREE";
        return name.toUpperCase();
    }

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
        anchors.fill: parent
        spacing: 12

        // ---------------- NETWORK ----------------
        SectionCard {
            Layout.fillHeight: true
            Layout.preferredHeight: 100
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

            // As many networks as fit
            Item {
                id: netList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                readonly property int capacity: Math.max(1, Math.floor(height / 40))

                Text {
                    visible: Net.radioOn && page.networks.length === 0
                    text: "No networks found"
                    color: Theme.alpha(Theme.fg, 0.7)
                    font.family: Theme.mono
                    font.pixelSize: 12
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: Net.radioOn ? page.networks.slice(0, netList.capacity) : []

                        Column {
                            id: net

                            required property var modelData

                            readonly property bool known: page.knownNames.indexOf(modelData.ssid) >= 0

                            width: parent.width
                            spacing: 4

                            Item {
                                width: parent.width
                                height: 36

                                Rectangle {
                                    anchors.fill: parent
                                    color: hover.containsMouse ? Theme.alpha(Theme.fg, 0.07) : (net.modelData.inUse ? Theme.alpha(Theme.primary, 0.2) : "transparent")
                                }

                                Glyph {
                                    kind: "wifi"
                                    level: net.modelData.signal
                                    tint: net.modelData.inUse ? Theme.gold : Theme.fg
                                    x: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    x: 36
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 36 - 130
                                    elide: Text.ElideRight
                                    text: net.modelData.ssid
                                    color: Theme.fg
                                    font.family: Theme.mono
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Glyph {
                                    visible: net.modelData.secured
                                    kind: "lock"
                                    tint: Theme.alpha(Theme.fg, 0.7)
                                    anchors.right: tag.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: tag
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 86
                                    horizontalAlignment: Text.AlignRight
                                    text: net.modelData.inUse ? "CONNECTED" : (net.known ? "SAVED" : (net.modelData.secured ? "" : "OPEN"))
                                    color: Theme.gold
                                    font.family: Theme.mono
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    id: hover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        if (net.modelData.inUse) {
                                            page.wifiMessage = "";
                                            Quickshell.execDetached(["nmcli", "connection", "down", "id", net.modelData.ssid]);
                                            afterAction.restart();
                                        } else if (net.known || !net.modelData.secured) {
                                            page.wifiConnect(net.modelData.ssid, "");
                                        } else {
                                            page.asking = net.modelData.ssid;
                                        }
                                    }
                                }
                            }

                            // Password prompt for a new protected network
                            Item {
                                visible: page.asking === net.modelData.ssid
                                width: parent.width
                                height: 34

                                Chamfer {
                                    anchors.fill: parent
                                    cut: 5
                                    strokeColor: Theme.alpha(Theme.gold, 0.8)
                                    fillTop: "transparent"
                                }

                                TextInput {
                                    id: password
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    color: Theme.fg
                                    selectionColor: Theme.primary
                                    selectedTextColor: Theme.onPrimary
                                    font.family: Theme.mono
                                    font.pixelSize: 13
                                    clip: true

                                    onVisibleChanged: {
                                        if (visible) {
                                            text = "";
                                            forceActiveFocus();
                                        }
                                    }

                                    onAccepted: {
                                        page.wifiConnect(net.modelData.ssid, text);
                                        page.asking = "";
                                    }

                                    Keys.onEscapePressed: page.asking = ""
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: password.text === ""
                                    text: "Password, then Enter"
                                    color: Theme.alpha(Theme.fg, 0.5)
                                    font.family: Theme.mono
                                    font.pixelSize: 13
                                }
                            }
                        }
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
                    visible: Net.radioOn && page.networks.length > netList.capacity
                    text: "+" + (page.networks.length - netList.capacity) + " more"
                    color: Theme.gold
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        // ---------------- BLUETOOTH ----------------
        SectionCard {
            Layout.fillHeight: true
            Layout.preferredHeight: 120
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

            Item {
                id: btList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                readonly property var shown: page.fitDevices(page.btDevices, height)

                Column {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: btList.shown

                        Column {
                            id: dev

                            required property var modelData

                            readonly property var d: modelData
                            readonly property string cardName: "bluez_card." + d.address.replace(/:/g, "_")
                            readonly property var card: page.btCards[cardName] ?? null

                            // One button per distinct profile label
                            readonly property var profileButtons: {
                                const out = [];
                                const seen = {};
                                if (dev.card) {
                                    for (let i = 0; i < dev.card.profiles.length; i++) {
                                        const label = page.profileLabel(dev.card.profiles[i].name);
                                        if (!seen[label]) {
                                            seen[label] = true;
                                            out.push({ name: dev.card.profiles[i].name, label: label });
                                        }
                                    }
                                }
                                return out;
                            }

                            width: parent.width
                            spacing: 6

                            Item {
                                width: parent.width
                                height: 44

                                Glyph {
                                    id: devIcon
                                    kind: dev.d.icon.indexOf("headset") >= 0 || dev.d.icon.indexOf("headphone") >= 0 ? "headphones" : "bluetooth"
                                    tint: dev.d.connected ? Theme.gold : Theme.alpha(Theme.fg, 0.8)
                                    x: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.left: devIcon.right
                                    anchors.leftMargin: 12
                                    anchors.right: devButton.left
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3

                                    Text {
                                        width: parent.width
                                        text: dev.d.name
                                        color: Theme.fg
                                        font.family: Theme.mono
                                        font.pixelSize: 13
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Row {
                                        spacing: 10

                                        Text {
                                            text: dev.d.state === BluetoothDeviceState.Connecting ? "Connecting..." : (dev.d.state === BluetoothDeviceState.Disconnecting ? "Disconnecting..." : (dev.d.connected ? "Connected" : (dev.d.paired ? "Paired" : "Available")))
                                            color: dev.d.connected ? Theme.gold : Theme.alpha(Theme.fg, 0.65)
                                            font.family: Theme.mono
                                            font.pixelSize: 11
                                        }

                                        Row {
                                            visible: dev.d.connected && dev.d.batteryAvailable
                                            spacing: 6

                                            Meter {
                                                width: 40
                                                height: 6
                                                anchors.verticalCenter: parent.verticalCenter
                                                value: dev.d.battery
                                                lowIsBad: true
                                            }

                                            Text {
                                                text: Math.round(dev.d.battery * 100) + "%"
                                                color: Theme.fg
                                                font.family: Theme.mono
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }
                                    }
                                }

                                ActionButton {
                                    id: devButton
                                    width: 116
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: dev.d.connected ? "DISCONNECT" : (dev.d.paired ? "CONNECT" : "PAIR")
                                    active: dev.d.connected

                                    onClicked: {
                                        if (dev.d.connected) {
                                            dev.d.disconnect();
                                        } else if (dev.d.paired) {
                                            dev.d.connect();
                                        } else {
                                            dev.d.trusted = true;
                                            dev.d.pair();
                                        }
                                    }
                                }
                            }

                            // Audio profile of a connected device
                            Flow {
                                visible: dev.d.connected && dev.profileButtons.length > 0
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: dev.profileButtons

                                    ActionButton {
                                        required property var modelData

                                        label: modelData.label
                                        active: dev.card !== null && page.profileLabel(dev.card.active) === modelData.label

                                        onClicked: {
                                            Quickshell.execDetached(["pactl", "set-card-profile", dev.cardName, modelData.name]);
                                            afterProfile.restart();
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: dev.d.connected && dev.profileButtons.length > 1
                                width: parent.width
                                text: "A2DP: music quality.  HANDS-FREE: microphone, lower quality."
                                color: Theme.alpha(Theme.fg, 0.55)
                                font.family: Theme.mono
                                font.pixelSize: 10
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }
}
