import QtQuick
import Quickshell.Bluetooth

// One Bluetooth device: icon, name, state, battery, a connect button,
// and (when connected) its audio profiles.
Column {
    id: row

    property var device: null
    property var card: null            // from pactl: { active, profiles: [{ name, priority }] }

    signal profileChosen(string name)

    readonly property var d: device

    function label(name) {
        if (name.indexOf("a2dp") === 0)
            return "A2DP";
        if (name.indexOf("headset") === 0)
            return "HANDS-FREE";
        return name.toUpperCase();
    }

    // One button per distinct profile label
    readonly property var profileButtons: {
        const out = [];
        const seen = {};
        if (row.card) {
            for (let i = 0; i < row.card.profiles.length; i++) {
                const l = row.label(row.card.profiles[i].name);
                if (!seen[l]) {
                    seen[l] = true;
                    out.push({ name: row.card.profiles[i].name, label: l });
                }
            }
        }
        return out;
    }

    spacing: 6

    Item {
        width: parent.width
        height: 44

        Glyph {
            id: devIcon
            kind: row.d.icon.indexOf("headset") >= 0 || row.d.icon.indexOf("headphone") >= 0 ? "headphones" : "bluetooth"
            tint: row.d.connected ? Theme.gold : Theme.alpha(Theme.fg, 0.8)
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
                text: row.d.name
                color: Theme.fg
                font.family: Theme.mono
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            Row {
                spacing: 10

                Text {
                    text: row.d.state === BluetoothDeviceState.Connecting ? "Connecting..." : (row.d.state === BluetoothDeviceState.Disconnecting ? "Disconnecting..." : (row.d.connected ? "Connected" : (row.d.paired ? "Paired" : "Available")))
                    color: row.d.connected ? Theme.gold : Theme.alpha(Theme.fg, 0.65)
                    font.family: Theme.mono
                    font.pixelSize: 11
                }

                Row {
                    visible: row.d.connected && row.d.batteryAvailable
                    spacing: 6

                    Meter {
                        width: 40
                        height: 6
                        anchors.verticalCenter: parent.verticalCenter
                        value: row.d.battery
                        lowIsBad: true
                    }

                    Text {
                        text: Math.round(row.d.battery * 100) + "%"
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
            label: row.d.connected ? "DISCONNECT" : (row.d.paired ? "CONNECT" : "PAIR")
            active: row.d.connected

            onClicked: {
                if (row.d.connected) {
                    row.d.disconnect();
                } else if (row.d.paired) {
                    row.d.connect();
                } else {
                    row.d.trusted = true;
                    row.d.pair();
                }
            }
        }
    }

    Flow {
        visible: row.d.connected && row.profileButtons.length > 0
        width: parent.width
        spacing: 8

        Repeater {
            model: row.profileButtons

            ActionButton {
                required property var modelData

                label: modelData.label
                active: row.card !== null && row.label(row.card.active) === modelData.label
                onClicked: row.profileChosen(modelData.name)
            }
        }
    }

    Text {
        visible: row.d.connected && row.profileButtons.length > 1
        width: parent.width
        text: "A2DP: music quality.  HANDS-FREE: microphone, lower quality."
        color: Theme.alpha(Theme.fg, 0.55)
        font.family: Theme.mono
        font.pixelSize: 10
        wrapMode: Text.Wrap
    }
}
