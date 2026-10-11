import QtQuick
import QtQuick.Layouts

Item {
    id: page

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 12

        // ---------------- NOW PLAYING ----------------
        SectionCard {
            icon: "note"
            title: "NOW PLAYING"
            subtitle: Media.present ? (Media.playing ? "PLAYING" : "PAUSED") : ""

            Text {
                visible: !Media.present
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "No media player is running"
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 13
            }

            // Album art
            Item {
                visible: Media.present
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 250
                Layout.preferredHeight: 250

                Chamfer {
                    anchors.fill: parent
                    cut: 12
                    strokeColor: Theme.alpha(Theme.gold, 0.8)
                    fillTop: Theme.alpha(Theme.fg, 0.06)
                }

                Image {
                    id: cover
                    anchors.fill: parent
                    anchors.margins: 8
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    visible: status === Image.Ready
                }

                Glyph {
                    visible: cover.status !== Image.Ready
                    kind: "note"
                    tint: Theme.alpha(Theme.gold, 0.7)
                    anchors.centerIn: parent
                    scale: 5
                }
            }

            Text {
                visible: Media.present
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Media.title || "Unknown title"
                color: Theme.fg
                font.family: Theme.serif
                font.pixelSize: 21
                elide: Text.ElideRight
            }

            Text {
                visible: Media.present
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Media.artist || "Unknown artist"
                color: Theme.gold
                font.family: Theme.mono
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                visible: Media.present && Media.album !== ""
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Media.album
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            // Seek bar
            Item {
                visible: Media.present
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                Text {
                    id: elapsed
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Fmt.clock(Media.position)
                    color: Theme.alpha(Theme.fg, 0.8)
                    font.family: Theme.mono
                    font.pixelSize: 11
                }

                Text {
                    id: total
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.length > 0 ? Fmt.clock(Media.length) : "--:--"
                    color: Theme.alpha(Theme.fg, 0.8)
                    font.family: Theme.mono
                    font.pixelSize: 11
                }

                Slider {
                    anchors.left: elapsed.right
                    anchors.right: total.left
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    height: parent.height
                    live: false
                    enabled: Media.canSeek && Media.length > 0
                    value: Media.progress
                    onMoved: v => Media.seekTo(v)
                }
            }

            // Transport
            Item {
                visible: Media.present
                Layout.fillWidth: true
                Layout.preferredHeight: 38

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    ActionButton {
                        icon: "prev"
                        onClicked: Media.previous()
                    }

                    ActionButton {
                        icon: Media.playing ? "pause" : "play"
                        active: Media.playing
                        onClicked: Media.toggle()
                    }

                    ActionButton {
                        icon: "next"
                        onClicked: Media.next()
                    }
                }
            }
        }

        // ---------------- SPECTRUM (only while there is a player) ----------------
        SectionCard {
            visible: Media.present
            icon: "speaker"
            title: "SPECTRUM"
            subtitle: Media.playing ? "LIVE" : ""

            Visualizer {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                active: Media.playing
            }
        }
    }
}
