import QtQuick
import Quickshell
import Quickshell.Io

// A text file kept in step with the program. It is read when the shell starts, read again when something else
// changes it on disk (a phone through Syncthing, say), and saved a moment after the last change.
// Changes from disk are held back while a save is waiting, so they can't overwrite what you just did.
Scope {
    id: store

    property string path: ""
    property int delay: 600
    property bool watch: true

    // The file's contents were loaded, or changed on disk
    signal loaded(string text)

    property string pending: ""

    function save(content) {
        pending = content;
        saver.restart();
    }

    readonly property string diskText: {
        try {
            return file.text();
        } catch (e) {
            return "";
        }
    }

    onDiskTextChanged: {
        if (!saver.running)
            loaded(diskText);
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", path.slice(0, path.lastIndexOf("/"))]);
        loaded(diskText);
    }

    FileView {
        id: file
        path: store.path
        blockLoading: true
        watchChanges: store.watch
        onFileChanged: reload()
    }

    Timer {
        id: saver
        interval: store.delay
        onTriggered: file.setText(store.pending)
    }
}
