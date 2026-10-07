import QtQuick
import Quickshell
import Quickshell.Io

Panel {
    id: root

    cardWidth: 580
    cardHeight: 430

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
        anchors.margins: 20
        spacing: 14

        Item {
            width: parent.width
            height: 36

            Text {
                id: title
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
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
                font.pixelSize: 16
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
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: "command me"
                color: Theme.alpha(Theme.fg, 0.4)
                font.family: Theme.mono
                font.pixelSize: 16
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.alpha(Theme.gold, 0.6)
        }

        ListView {
            id: resultsView
            width: parent.width
            height: 320
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 4
            model: root.results
            currentIndex: 0

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index
                readonly property bool selected: index === resultsView.currentIndex

                width: resultsView.width
                height: 40
                radius: 8
                color: selected ? Theme.primary : "transparent"

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.name
                    color: row.selected ? Theme.onPrimary : Theme.fg
                    font.family: Theme.mono
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.entry.genericName
                    color: row.selected ? Theme.alpha(Theme.onPrimary, 0.7) : Theme.alpha(Theme.fg, 0.45)
                    font.family: Theme.mono
                    font.pixelSize: 12
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
