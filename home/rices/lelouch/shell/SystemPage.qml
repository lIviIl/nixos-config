import QtQuick

Flickable {
    id: page

    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function memFrac(v) {
        return SysInfo.mem.total > 0 ? v / SysInfo.mem.total : 0;
    }

    // A label on the left, a value on the right
    component StatRow: Item {
        id: row

        property string label: ""
        property string value: ""
        property color valueColor: Theme.fg

        signal clicked()

        width: parent ? parent.width : 0
        height: 20

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            color: Theme.alpha(Theme.fg, 0.7)
            font.family: Theme.mono
            font.pixelSize: 12
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: row.value
            color: row.valueColor
            font.family: Theme.mono
            font.pixelSize: 12
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: row.clicked()
        }
    }

    Column {
        id: column
        width: page.width
        spacing: 12

        // ---------------- CPU ----------------
        SectionCard {
            width: parent.width
            title: "CPU"
            subtitle: Math.round(SysInfo.cpuTotal) + "%   " + Math.round(SysInfo.cpuTemp) + "°C"

            Sparkline {
                width: parent.width
                height: 64
                values: SysInfo.cpuHistory
                maxValue: 100
            }

            Repeater {
                model: SysInfo.cpuCores.length

                Item {
                    id: coreRow

                    required property int index

                    width: parent.width
                    height: 20

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "T" + coreRow.index
                        color: Theme.alpha(Theme.fg, 0.7)
                        font.family: Theme.mono
                        font.pixelSize: 12
                    }

                    Meter {
                        x: 34
                        width: parent.width - 34 - 150
                        anchors.verticalCenter: parent.verticalCenter
                        value: SysInfo.cpuCores[coreRow.index] / 100
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(SysInfo.cpuCores[coreRow.index]) + "%   " + Fmt.mhz(SysInfo.cpuFreq[coreRow.index] || 0)
                        color: Theme.fg
                        font.family: Theme.mono
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
        }

        // ---------------- MEMORY ----------------
        SectionCard {
            width: parent.width
            title: "MEMORY"
            subtitle: Fmt.bytes(SysInfo.mem.active) + " / " + Fmt.bytes(SysInfo.mem.total)

            Sparkline {
                width: parent.width
                height: 54
                values: SysInfo.memHistory
                maxValue: 100
            }

            // Used, buffers, cached; the rest is free
            Item {
                id: stack
                width: parent.width
                height: 12

                Rectangle {
                    anchors.fill: parent
                    color: Theme.alpha(Theme.fg, 0.14)
                }

                Row {
                    height: parent.height

                    Rectangle {
                        height: parent.height
                        width: stack.width * page.memFrac(SysInfo.mem.used)
                        color: Theme.primary
                    }

                    Rectangle {
                        height: parent.height
                        width: stack.width * page.memFrac(SysInfo.mem.buffers)
                        color: Theme.alpha(Theme.fg, 0.55)
                    }

                    Rectangle {
                        height: parent.height
                        width: stack.width * page.memFrac(SysInfo.mem.cached)
                        color: Theme.alpha(Theme.gold, 0.85)
                    }
                }
            }

            StatRow { label: "USED"; value: Fmt.bytes(SysInfo.mem.used); valueColor: Theme.primary }
            StatRow { label: "BUFFERS"; value: Fmt.bytes(SysInfo.mem.buffers) }
            StatRow { label: "CACHED"; value: Fmt.bytes(SysInfo.mem.cached); valueColor: Theme.gold }
            StatRow { label: "FREE"; value: Fmt.bytes(SysInfo.mem.free) }

            Meter {
                width: parent.width
                value: SysInfo.mem.swapTotal > 0 ? SysInfo.mem.swapUsed / SysInfo.mem.swapTotal : 0
            }

            StatRow {
                label: "SWAP"
                value: SysInfo.mem.swapTotal > 0 ? Fmt.bytes(SysInfo.mem.swapUsed) + " / " + Fmt.bytes(SysInfo.mem.swapTotal) : "none"
            }
        }

        // ---------------- GPU ----------------
        SectionCard {
            width: parent.width
            title: "GPU"
            subtitle: SysInfo.gpuAvailable ? Math.round(SysInfo.gpuBusy) + "%   " + Math.round(SysInfo.cpuTemp) + "°C" : ""

            Text {
                visible: !SysInfo.gpuAvailable
                text: "No Intel GPU counters found"
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 12
            }

            Sparkline {
                visible: SysInfo.gpuAvailable
                width: parent.width
                height: 54
                values: SysInfo.gpuHistory
                maxValue: 100
            }

            Meter {
                visible: SysInfo.gpuAvailable
                width: parent.width
                value: SysInfo.gpuMaxFreq > 0 ? SysInfo.gpuFreq / SysInfo.gpuMaxFreq : 0
            }

            StatRow {
                visible: SysInfo.gpuAvailable
                label: "CLOCK"
                value: Fmt.mhz(SysInfo.gpuFreq) + " / " + Fmt.mhz(SysInfo.gpuMaxFreq)
            }
        }

        // ---------------- STORAGE ----------------
        SectionCard {
            width: parent.width
            title: "STORAGE"
            subtitle: "R " + Fmt.rate(SysInfo.ioRead) + "   W " + Fmt.rate(SysInfo.ioWrite)

            Sparkline {
                width: parent.width
                height: 54
                values: SysInfo.ioReadHistory
                values2: SysInfo.ioWriteHistory
                maxValue: 0
            }

            Repeater {
                model: SysInfo.disks

                Column {
                    id: disk

                    required property var modelData

                    width: parent.width
                    spacing: 4

                    StatRow {
                        label: disk.modelData.mount
                        value: Fmt.bytes(disk.modelData.used) + " / " + Fmt.bytes(disk.modelData.size)
                    }

                    Meter {
                        width: parent.width
                        value: disk.modelData.used / disk.modelData.size
                    }
                }
            }
        }

        // ---------------- NETWORK ----------------
        SectionCard {
            width: parent.width
            title: "NETWORK"
            subtitle: "↓ " + Fmt.rate(SysInfo.netDown) + "   ↑ " + Fmt.rate(SysInfo.netUp)

            Sparkline {
                width: parent.width
                height: 64
                values: SysInfo.netDownHistory
                values2: SysInfo.netUpHistory
                maxValue: 0
            }

            StatRow { label: "DOWN"; value: Fmt.rate(SysInfo.netDown); valueColor: Theme.primary }
            StatRow { label: "UP"; value: Fmt.rate(SysInfo.netUp); valueColor: Theme.crimson }

            Repeater {
                model: SysInfo.addresses

                StatRow {
                    required property var modelData

                    label: "LOCAL IP"
                    value: modelData.addr
                }
            }

            StatRow {
                label: "LATENCY"
                value: SysInfo.pingMs >= 0 ? SysInfo.pingMs.toFixed(1) + " ms" : "--"
            }

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
            width: parent.width
            title: "BATTERY"
            subtitle: SysInfo.battery.present ? (SysInfo.battery.capacity || 0) + "%   " + SysInfo.battery.status : ""

            Text {
                visible: !SysInfo.battery.present
                text: "No battery detected"
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 12
            }

            Meter {
                visible: SysInfo.battery.present
                width: parent.width
                value: (SysInfo.battery.capacity || 0) / 100
                fill: SysInfo.battery.status === "Charging" ? Theme.gold : Theme.primary
            }

            StatRow {
                visible: SysInfo.battery.present
                label: "POWER DRAW"
                value: (SysInfo.battery.watts || 0).toFixed(1) + " W"
            }

            StatRow {
                visible: SysInfo.battery.present
                label: SysInfo.battery.status === "Charging" ? "TIME TO FULL" : "TIME REMAINING"
                value: Fmt.minutes(SysInfo.battery.minutes || -1)
            }

            StatRow {
                visible: SysInfo.battery.present
                label: "HEALTH"
                value: Math.round(SysInfo.battery.health || 0) + "%   of design capacity"
                valueColor: (SysInfo.battery.health || 100) < 70 ? Theme.crimson : Theme.fg
            }

            StatRow {
                visible: SysInfo.battery.present && (SysInfo.battery.cycles || 0) > 0
                label: "CHARGE CYCLES"
                value: String(SysInfo.battery.cycles)
            }
        }
    }
}
