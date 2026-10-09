import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: root

    readonly property int maxToasts: 6
    property int counter: 0
    property var live: ({})

    // Remove a toast from the list (animated) and tell the app it was dismissed
    function dismiss(key) {
        for (let i = 0; i < toasts.count; i++) {
            if (toasts.get(i).key === key) {
                toasts.remove(i);
                break;
            }
        }
        const n = live[key];
        if (n) {
            n.dismiss();
            delete live[key];
        }
    }

    // Toast data is copied here so a card can finish animating out after its notification is gone
    ListModel {
        id: toasts
    }

    NotificationServer {
        id: server

        onNotification: notification => {
            notification.tracked = true;

            const key = root.counter++;
            root.live[key] = notification;
            toasts.append({
                key: key,
                summary: notification.summary,
                body: notification.body,
                critical: notification.urgency === NotificationUrgency.Critical,
                low: notification.urgency === NotificationUrgency.Low
            });

            // Never stack more than fits: drop the oldest
            if (toasts.count > root.maxToasts)
                root.dismiss(toasts.get(0).key);
        }
    }

    // Full height and never resized; only the toasts themselves are clickable
    PanelWindow {
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

        // Extra room on the left so the rebound isn't clipped
        implicitWidth: 380 + 48

        Item {
            id: hitbox
            anchors.right: parent.right
            width: 380
            height: view.contentHeight
        }

        ListView {
            id: view
            anchors.top: parent.top
            anchors.right: parent.right
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
                onDismissRequested: root.dismiss(key)
            }
        }
    }
}
