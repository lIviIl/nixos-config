import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Flickable {
    id: page

    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // The player that is playing, otherwise the first one
    readonly property var players: Mpris.players.values
    readonly property var player: players.filter(p => p.playbackState === MprisPlaybackState.Playing)[0] ?? players[0] ?? null
    readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }

    // The position doesn't update reactively on its own: nudge it while playing
    Timer {
        interval: 500
        running: page.playing
        repeat: true
        onTriggered: page.player.positionChanged()
    }

    Column {
        id: column
        width: page.width
        spacing: 12

        // ---------------- NOW PLAYING ----------------
        SectionCard {
            width: parent.width
            icon: "note"
            title: "NOW PLAYING"
            subtitle: page.player ? (page.playing ? "PLAYING" : "PAUSED") : ""

            Text {
                visible: !page.player
                text: "No media player is running"
                color: Theme.alpha(Theme.fg, 0.7)
                font.family: Theme.mono
                font.pixelSize: 12
            }

            Row {
                visible: !!page.player
                width: parent.width
                spacing: 16

                // Album art
                Item {
                    width: 132
                    height: 132

                    Chamfer {
                        anchors.fill: parent
                        cut: 8
                        strokeColor: Theme.alpha(Theme.gold, 0.8)
                        fillTop: Theme.alpha(Theme.fg, 0.06)
                    }

                    Image {
                        id: cover
                        anchors.fill: parent
                        anchors.margins: 6
                        source: page.player ? page.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Glyph {
                        visible: cover.status !== Image.Ready
                        kind: "note"
                        tint: Theme.alpha(Theme.gold, 0.7)
                        anchors.centerIn: parent
                        scale: 3
                    }
                }

                Column {
                    width: parent.width - 132 - 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        width: parent.width
                        text: page.player ? (page.player.trackTitle || "Unknown title") : ""
                        color: Theme.fg
                        font.family: Theme.serif
                        font.pixelSize: 20
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: page.player ? (page.player.trackArtist || "Unknown artist") : ""
                        color: Theme.gold
                        font.family: Theme.mono
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: page.player ? (page.player.trackAlbum || "") : ""
                        color: Theme.alpha(Theme.fg, 0.7)
                        font.family: Theme.mono
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }

            // Seek bar
            Item {
                visible: !!page.player
                width: parent.width
                height: 28

                Text {
                    id: elapsed
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.player ? page.clock(page.player.position) : "0:00"
                    color: Theme.alpha(Theme.fg, 0.8)
                    font.family: Theme.mono
                    font.pixelSize: 11
                }

                Text {
                    id: total
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.player ? page.clock(page.player.length) : "0:00"
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
                    enabled: !!page.player && page.player.canSeek
                    value: page.player && page.player.length > 0 ? page.player.position / page.player.length : 0
                    onMoved: v => page.player.position = v * page.player.length
                }
            }

            // Transport
            Item {
                visible: !!page.player
                width: parent.width
                height: 36

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    ActionButton {
                        icon: "prev"
                        onClicked: page.player.previous()
                    }

                    ActionButton {
                        icon: page.playing ? "pause" : "play"
                        active: page.playing
                        onClicked: page.player.togglePlaying()
                    }

                    ActionButton {
                        icon: "next"
                        onClicked: page.player.next()
                    }
                }
            }
        }

        // ---------------- SPECTRUM ----------------
        SectionCard {
            width: parent.width
            icon: "speaker"
            title: "SPECTRUM"
            subtitle: page.playing ? "LIVE" : ""

            Visualizer {
                width: parent.width
                height: 110
                active: page.playing
            }
        }
    }
}
