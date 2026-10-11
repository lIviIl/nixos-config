pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The current media player, shared by the bar, the Media tab and the lock screen.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: players.filter(p => p.playbackState === MprisPlaybackState.Playing)[0] ?? players[0] ?? null
    readonly property bool present: player !== null
    readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing
    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album: player ? (player.trackAlbum || "") : ""
    readonly property string art: player ? (player.trackArtUrl || "") : ""
    readonly property real position: player ? player.position : 0
    readonly property bool canSeek: player !== null && player.canSeek

    // Some players report a bogus length (equal to the position) right after a seek or a track
    // change. Keep the last sane length for the current track instead.
    property real length: 0
    property string trackKey: ""
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    function syncLength() {
        if (!player) {
            length = 0;
            trackKey = "";
            return;
        }
        const key = title + "|" + artist;
        if (key !== trackKey) {
            trackKey = key;
            length = 0;
        }
        const l = player.length;
        if (l > 0 && (length === 0 || Math.abs(l - player.position) > 1.5))
            length = l;
    }

    function seekTo(fraction) {
        if (player && canSeek && length > 0)
            player.position = fraction * length;
    }

    function toggle() {
        if (player)
            player.togglePlaying();
    }

    function next() {
        if (player)
            player.next();
    }

    function previous() {
        if (player)
            player.previous();
    }

    onTitleChanged: syncLength()
    onPlayerChanged: syncLength()

    // The position doesn't update reactively on its own: nudge it while playing
    Timer {
        interval: 500
        running: root.playing
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.player.positionChanged();
            root.syncLength();
        }
    }
}
