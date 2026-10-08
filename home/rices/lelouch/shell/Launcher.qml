import QtQuick
import Quickshell
import Quickshell.Io

Panel {
    id: root

    readonly property int maxRows: 7
    readonly property int visibleRows: Math.max(1, Math.min(results.length, maxRows))

    cardWidth: 640
    cardHeight: 100 + visibleRows * 46

    Behavior on cardHeight {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    // 0 = name starts with the query, 1 = name contains it, 2 = description/keywords match, -1 = no match
    function score(entry, q) {
        const name = (entry.name || "").toLowerCase();
        if (name.startsWith(q))
            return 0;
        if (name.includes(q))
            return 1;
        const keywords = entry.keywords ? Array.from(entry.keywords).join(" ") : "";
        const extra = ((entry.genericName || "") + " " + (entry.comment || "") + " " + keywords).toLowerCase();
        return extra.includes(q) ? 2 : -1;
    }

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        const apps = DesktopEntries.applications.values;
        const matches = [];
        for (let i = 0; i < apps.length; i++) {
            const s = q === "" ? 0 : root.score(apps[i], q);
            if (s >= 0)
                matches.push({ entry: apps[i], name: apps[i].name, score: s });
        }
        matches.sort((a, b) => (a.score - b.score) || a.name.localeCompare(b.name));
        return matches;
    }

    function launch(entry) {
        open = false;
        if (entry.runInTerminal)
            Quickshell.execDetached(["kitty", "-e"].concat(Array.from(entry.command)));
        else
            entry.execute();
    }

    function launchCurrent() {
        if (resultsView.currentIndex >= 0 && resultsView.currentIndex < results.length)
            launch(results[resultsView.currentIndex].entry);
    }

    onOpenChanged: {
        if (open) {
            input.text = "";
            resultsView.currentIndex = 0;
            Qt.callLater(() => input.forceActiveFocus());
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.open = !root.open;
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Header: the kanji and the input share a baseline
        Item {
            width: parent.width
            height: 38

            Text {
                id: title
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.baseline: input.baseline
                text: "絶対遵守"
                color: Theme.gold
                font.family: Theme.serif
                font.pixelSize: 18
            }

            TextInput {
                id: input
                anchors.left: title.right
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                selectionColor: Theme.primary
                selectedTextColor: Theme.onPrimary
                font.family: Theme.mono
                font.pixelSize: 17
                clip: true

                onTextChanged: resultsView.currentIndex = 0

                Keys.onEscapePressed: root.open = false
                Keys.onDownPressed: resultsView.incrementCurrentIndex()
                Keys.onUpPressed: resultsView.decrementCurrentIndex()
                Keys.onReturnPressed: root.launchCurrent()
                Keys.onEnterPressed: root.launchCurrent()
            }

            Text {
                anchors.left: input.left
                anchors.baseline: input.baseline
                visible: input.text === ""
                text: "command me"
                color: Theme.alpha(Theme.fg, 0.5)
                font.family: Theme.mono
                font.pixelSize: 17
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.alpha(Theme.gold, 0.7)
        }

        ListView {
            id: resultsView
            width: parent.width
            height: root.visibleRows * 46
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 4
            model: root.results
            currentIndex: 0

            Text {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: "No match"
                color: Theme.alpha(Theme.fg, 0.6)
                font.family: Theme.mono
                font.pixelSize: 14
            }

            delegate: Item {
                id: row

                required property var modelData
                required property int index
                readonly property bool selected: index === resultsView.currentIndex

                width: resultsView.width
                height: 42

                Rectangle {
                    anchors.fill: parent
                    color: row.selected ? Theme.alpha(Theme.primary, 0.28) : "transparent"

                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                // Crimson marker on the selected row
                Rectangle {
                    width: 3
                    height: parent.height
                    color: Theme.crimson
                    opacity: row.selected ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.name
                    color: Theme.fg
                    font.family: Theme.mono
                    font.pixelSize: 15
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.entry.genericName
                    color: Theme.alpha(Theme.fg, 0.75)
                    font.family: Theme.mono
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: resultsView.currentIndex = row.index
                    onClicked: root.launch(row.modelData.entry)
                }
            }
        }
    }
}
