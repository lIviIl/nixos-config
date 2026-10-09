import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// The lock screen: a Wayland session lock whose surfaces are drawn by LockScene,
// authenticated through PAM, with the blast-door exit in Doors.
Scope {
    id: root

    function lock() {
        if (lockSession.locked || doors.open)
            return;
        LockState.typedText = "";
        LockState.granted = false;
        LockState.busy = false;
        LockState.status = "STATE YOUR WILL";
        LockState.locked = true;
        lockSession.locked = true;
    }

    function submit() {
        if (LockState.typedText === "" || pam.active)
            return;
        LockState.busy = true;
        LockState.status = "AUTHORIZING";
        pam.start();
    }

    function grant() {
        LockState.granted = true;
        LockState.status = "COMMAND ACCEPTED";
        toDoors.start();
    }

    function handleKey(event) {
        event.accepted = true;
        if (LockState.granted || LockState.busy)
            return;

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            submit();
        else if (event.key === Qt.Key_Backspace)
            LockState.typedText = LockState.typedText.slice(0, -1);
        else if (event.key === Qt.Key_Escape)
            LockState.typedText = "";
        else if (event.text.length === 1 && event.text.charCodeAt(0) >= 32 && !(event.modifiers & Qt.ControlModifier))
            LockState.typedText += event.text;
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }

    // Success: let the flare build, hand over to the doors overlay (white at that instant),
    // unlock underneath it, then open the doors.
    Timer {
        id: toDoors
        interval: 440
        onTriggered: {
            doors.open = true;
            toUnlock.start();
        }
    }

    Timer {
        id: toUnlock
        interval: 160
        onTriggered: {
            lockSession.locked = false;
            LockState.locked = false;
            doors.play();
        }
    }

    Timer {
        id: statusReset
        interval: 1800
        onTriggered: {
            if (!LockState.granted && !LockState.busy)
                LockState.status = "STATE YOUR WILL";
        }
    }

    PamContext {
        id: pam
        config: "lelouch-lock"

        onPamMessage: {
            if (pam.responseRequired)
                pam.respond(LockState.typedText);
        }

        onCompleted: result => {
            LockState.busy = false;
            if (result === PamResult.Success) {
                root.grant();
            } else {
                LockState.typedText = "";
                LockState.status = "COMMAND REJECTED";
                LockState.failPulse++;
                statusReset.restart();
            }
        }
    }

    Doors {
        id: doors

        onFinished: {
            LockState.granted = false;
            LockState.typedText = "";
        }
    }

    WlSessionLock {
        id: lockSession
        locked: false

        WlSessionLockSurface {
            LockScene {
                anchors.fill: parent
            }

            // Cursor position drives the parallax
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: mouse => {
                    LockState.px = (mouse.x / width - 0.5) * 2;
                    LockState.py = (mouse.y / height - 0.5) * 2;
                }
            }

            // Keyboard: there is no input box, the sigil is the feedback
            Item {
                focus: true
                Keys.onPressed: event => root.handleKey(event)
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
