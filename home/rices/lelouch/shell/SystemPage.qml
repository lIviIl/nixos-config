import QtQuick
import QtQuick.Layouts

Item {
    id: page

    property var wattHistory: []

    function frac(v) {
        return SysInfo.mem.total > 0 ? v / SysInfo.mem.total : 0;
    }

    Connections {
        target: SysInfo

        function onBatteryChanged() {
            if (SysInfo.battery.present)
                page.wattHistory = SysInfo.push(page.wattHistory, SysInfo.battery.watts || 0);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        IdentityBanner {}

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 12

            // ---------------- CPU ----------------
            SectionCard {
                Layout.fillHeight: true
                title: "CPU"
                subtitle: Math.round(SysInfo.cpuTotal) + "%   " + Math.round(SysInfo.cpuTemp) + "°C"

                Sparkline {
                    values: SysInfo.cpuHistory
                    maxValue: 100
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: SysInfo.cpuCores.length > 4 ? 2 : 1
                    columnSpacing: 12
                    rowSpacing: 5

                    Repeater {
                        model: SysInfo.cpuCores.length

                        NameBar {
                            required property int index

                            label: "T" + index + "  ·  " + Fmt.mhz(SysInfo.cpuFreq[index] || 0)
                            value: Math.round(SysInfo.cpuCores[index] || 0) + "%"
                            fraction: (SysInfo.cpuCores[index] || 0) / 100
                        }
                    }
                }
            }

            // ---------------- MEMORY ----------------
            SectionCard {
                Layout.fillHeight: true
                title: "MEMORY"
                subtitle: Fmt.bytes(SysInfo.mem.active) + " / " + Fmt.bytes(SysInfo.mem.total)

                Sparkline {
                    values: SysInfo.memHistory
                    maxValue: 100
                }

                // Used, buffers, cached; the rest is free
                Item {
                    id: stack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.alpha(Theme.fg, 0.14)
                    }

                    Row {
                        height: parent.height

                        Rectangle { height: parent.height; width: stack.width * page.frac(SysInfo.mem.used); color: Theme.primary }
                        Rectangle { height: parent.height; width: stack.width * page.frac(SysInfo.mem.buffers); color: Theme.alpha(Theme.fg, 0.55) }
                        Rectangle { height: parent.height; width: stack.width * page.frac(SysInfo.mem.cached); color: Theme.alpha(Theme.gold, 0.85) }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 14
                    rowSpacing: 2

                    StatRow { label: "USED"; value: Fmt.bytes(SysInfo.mem.used); valueColor: Theme.primary }
                    StatRow { label: "BUFFERS"; value: Fmt.bytes(SysInfo.mem.buffers) }
                    StatRow { label: "CACHED"; value: Fmt.bytes(SysInfo.mem.cached); valueColor: Theme.gold }
                    StatRow { label: "FREE"; value: Fmt.bytes(SysInfo.mem.free) }
                }

                NameBar {
                    label: "SWAP"
                    value: SysInfo.mem.swapTotal > 0 ? Fmt.bytes(SysInfo.mem.swapUsed) + " / " + Fmt.bytes(SysInfo.mem.swapTotal) : "none"
                    fraction: SysInfo.mem.swapTotal > 0 ? SysInfo.mem.swapUsed / SysInfo.mem.swapTotal : 0
                }
            }

            // ---------------- GPU ----------------
            SectionCard {
                Layout.fillHeight: true
                title: "GPU"
                subtitle: SysInfo.gpuAvailable ? Math.round(SysInfo.gpuBusy) + "%   " + Math.round(SysInfo.cpuTemp) + "°C" : ""

                Text {
                    visible: !SysInfo.gpuAvailable
                    Layout.fillWidth: true
                    text: "No Intel GPU counters found"
                    color: Theme.alpha(Theme.fg, 0.7)
                    font.family: Theme.mono
                    font.pixelSize: 12
                }

                Sparkline {
                    visible: SysInfo.gpuAvailable
                    values: SysInfo.gpuHistory
                    maxValue: 100
                }

                NameBar {
                    visible: SysInfo.gpuAvailable
                    label: "UTILIZATION"
                    value: Math.round(SysInfo.gpuBusy) + "%"
                    fraction: SysInfo.gpuBusy / 100
                }

                NameBar {
                    visible: SysInfo.gpuAvailable
                    label: "CLOCK"
                    value: Fmt.mhz(SysInfo.gpuFreq) + " / " + Fmt.mhz(SysInfo.gpuMaxFreq)
                    fraction: SysInfo.gpuMaxFreq > 0 ? SysInfo.gpuFreq / SysInfo.gpuMaxFreq : 0
                }
            }

            // ---------------- STORAGE ----------------
            SectionCard {
                Layout.fillHeight: true
                title: "STORAGE"
                subtitle: "R " + Fmt.rate(SysInfo.ioRead) + "   W " + Fmt.rate(SysInfo.ioWrite)

                Sparkline {
                    values: SysInfo.ioReadHistory
                    values2: SysInfo.ioWriteHistory
                    maxValue: 0
                }

                Repeater {
                    model: SysInfo.disks

                    NameBar {
                        required property var modelData

                        label: modelData.mount
                        value: Fmt.bytes(modelData.used) + " / " + Fmt.bytes(modelData.size)
                        fraction: modelData.used / modelData.size
                    }
                }
            }

            // ---------------- NETWORK ----------------
            SectionCard {
                Layout.fillHeight: true
                title: "NETWORK"
                subtitle: "↓ " + Fmt.rate(SysInfo.netDown) + "   ↑ " + Fmt.rate(SysInfo.netUp)

                Sparkline {
                    values: SysInfo.netDownHistory
                    values2: SysInfo.netUpHistory
                    maxValue: 0
                }

                StatRow { label: "DOWN"; value: Fmt.rate(SysInfo.netDown); valueColor: Theme.primary }
                StatRow { label: "UP"; value: Fmt.rate(SysInfo.netUp); valueColor: Theme.crimson }
                StatRow { label: "LATENCY"; value: SysInfo.pingMs >= 0 ? SysInfo.pingMs.toFixed(1) + " ms" : "--" }

                StatRow {
                    label: "PUBLIC IP"
                    value: SysInfo.publicIp !== "" ? SysInfo.publicIp : "click to look up"
                    valueColor: SysInfo.publicIp !== "" ? Theme.fg : Theme.gold
                    onClicked: {
                        if (SysInfo.publicIp === "")
                            SysInfo.lookupPublicIp();
                    }
                }
            }

            // ---------------- BATTERY ----------------
            SectionCard {
                Layout.fillHeight: true
                title: "BATTERY"
                subtitle: SysInfo.battery.present ? SysInfo.battery.status : ""

                Text {
                    visible: !SysInfo.battery.present
                    Layout.fillWidth: true
                    text: "No battery detected"
                    color: Theme.alpha(Theme.fg, 0.7)
                    font.family: Theme.mono
                    font.pixelSize: 12
                }

                Sparkline {
                    visible: SysInfo.battery.present
                    values: page.wattHistory
                    maxValue: 0
                }

                NameBar {
                    visible: SysInfo.battery.present
                    label: "CHARGE"
                    value: (SysInfo.battery.capacity || 0) + "%"
                    fraction: (SysInfo.battery.capacity || 0) / 100
                    fill: SysInfo.battery.status === "Charging" ? Theme.gold : Theme.primary
                    lowIsBad: true
                }

                NameBar {
                    visible: SysInfo.battery.present
                    label: "HEALTH"
                    value: Math.round(SysInfo.battery.health || 0) + "%"
                    fraction: (SysInfo.battery.health || 0) / 100
                    lowIsBad: true
                }

                StatRow { visible: SysInfo.battery.present; label: "POWER DRAW"; value: (SysInfo.battery.watts || 0).toFixed(1) + " W" }
                StatRow { visible: SysInfo.battery.present; label: SysInfo.battery.status === "Charging" ? "TO FULL" : "REMAINING"; value: Fmt.minutes(SysInfo.battery.minutes || -1) }
            }
        }
    }
}
