import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: root

    readonly property int maxToasts: 6

    // Take a toast off the screen (animated). The notification itself stays in the history.
    function dismissToast(key) {
        for (let i = 0; i < toasts.count; i++) {
            if (toasts.get(i).key === key) {
                toasts.remove(i);
                break;
            }
        }
    }

    // Toast data is copied here so a card can finish animating out
    ListModel {
        id: toasts
    }

    NotificationServer {
        id: server

        // Apps only send action buttons if the server says it supports them
        actionsSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const key = History.add(notification);
            toasts.append({
                key: key,
                summary: notification.summary,
                body: notification.body,
                critical: notification.urgency === NotificationUrgency.Critical,
                low: notification.urgency === NotificationUrgency.Low
            });

            // Never stack more than fits: drop the oldest toast
            if (toasts.count > root.maxToasts)
                root.dismissToast(toasts.get(0).key);
        }
    }

    // Full height and never resized; only the toasts themselves are clickable.
    // It is wide enough for both toast positions, so stepping aside is an animation inside the window.
    PanelWindow {
        id: toastWindow

        // How far the toasts step aside while the command center is open (its width plus the gap)
        property real shift: Ui.centerOpen ? 712 : 0

        Behavior on shift {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region { item: hitbox }

        anchors {
            top: true
            right: true
            bottom: true
        }

        margins {
            top: 56
            right: 12
            bottom: 12
        }

        implicitWidth: 380 + 48 + 712

        Item {
            id: hitbox
            anchors.right: parent.right
            anchors.rightMargin: toastWindow.shift
            width: 380
            height: view.contentHeight
        }

        ListView {
            id: view
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: toastWindow.shift
            anchors.bottom: parent.bottom
            width: 380
            spacing: 8
            interactive: false
            model: toasts

            // Slide in from the right with a soft rebound
            add: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        from: 160
                        to: 0
                        duration: 400
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 140
                    }
                }
            }

            // Slide out and fade
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        to: 160
                        duration: 220
                        easing.type: Easing.InCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: 200
                    }
                }
            }

            // The rest glide into the gap
            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            delegate: Toast {
                onDismissRequested: root.dismissToast(key)
            }
        }
    }
}
