import QtQuick

// The double-outlined card every overlay surface uses: a gold chamfered edge with a faint
// primary-tinted glow at the top, and a thin inner highlight line.
Item {
    id: frame

    property real cut: 14

    Chamfer {
        anchors.fill: parent
        cut: frame.cut
        strokeColor: Theme.alpha(Theme.gold, 0.9)
        fillTop: Theme.alpha(Theme.mix(Theme.bg, Theme.primary, 0.18), 0.96)
        fillBottom: Theme.alpha(Theme.bg, 0.96)
    }

    Chamfer {
        anchors.fill: parent
        anchors.margins: 5
        cut: frame.cut - 4
        strokeColor: Theme.alpha(Theme.primary, 0.4)
        fillTop: "transparent"
    }
}
