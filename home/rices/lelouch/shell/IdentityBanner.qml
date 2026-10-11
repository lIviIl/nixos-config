import QtQuick
import QtQuick.Layouts

// Avatar (put a picture at ~/.face), user and hostname, uptime, kernel, session.
Item {
    id: banner

    Layout.fillWidth: true
    Layout.preferredHeight: 92

    Chamfer {
        anchors.fill: parent
        cut: 10
        strokeColor: Theme.alpha(Theme.gold, 0.8)
        fillTop: Theme.alpha(Theme.mix(Theme.bg, Theme.primary, 0.14), 0.9)
        fillBottom: Theme.alpha(Theme.bg, 0.9)
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 16

        Item {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64

            Chamfer {
                anchors.fill: parent
                cut: 8
                strokeColor: Theme.gold
                fillTop: Theme.alpha(Theme.primary, 0.3)
            }

            Image {
                id: face
                anchors.fill: parent
                anchors.margins: 4
                source: "file://" + Identity.home + "/.face"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                mipmap: true
                sourceSize.width: 256
                sourceSize.height: 256
                visible: status === Image.Ready
            }

            Text {
                visible: face.status !== Image.Ready
                anchors.centerIn: parent
                text: Identity.user.charAt(0).toUpperCase()
                color: Theme.gold
                font.family: Theme.serif
                font.pixelSize: 26
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: Identity.user
                color: Theme.fg
                font.family: Theme.serif
                font.pixelSize: 20
            }

            Text {
                text: "@" + Identity.hostname
                color: Theme.gold
                font.family: Theme.mono
                font.pixelSize: 13
                font.bold: true
            }
        }

        RowLayout {
            spacing: 22

            Repeater {
                model: [
                    { k: "UPTIME", v: Fmt.uptime(Identity.uptime) },
                    { k: "KERNEL", v: Identity.kernel },
                    { k: "SESSION", v: Identity.desktop }
                ]

                ColumnLayout {
                    required property var modelData

                    spacing: 3

                    Text {
                        text: parent.modelData.k
                        color: Theme.alpha(Theme.fg, 0.6)
                        font.family: Theme.mono
                        font.pixelSize: 11
                        font.letterSpacing: 2
                    }

                    Text {
                        text: parent.modelData.v
                        color: Theme.fg
                        font.family: Theme.mono
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
            }
        }
    }
}
