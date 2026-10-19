import QtQuick

// A thin gold separator between groups in the bar.
Item {
    width: 17
    height: 28

    Rectangle {
        anchors.centerIn: parent
        width: 1
        height: 16
        color: Theme.alpha(Theme.gold, 0.45)
    }
}
