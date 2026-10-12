import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// The lock screen: a Wayland session lock whose surfaces are drawn by LockScene,
// authenticated through PAM, with the red fade-out in Veil.
Scope {
    id: root

    function lock() {
        if (lockSession.locked || veil.open)
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
        toVeil.start();
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

    // Success: the emblem flies in until the screen is solid red, the veil takes over,
    // the session unlocks underneath it, then the red fades into the desktop.
    Timer {
        id: toVeil
        interval: 520
        onTriggered: {
            veil.open = true;
            toUnlock.start();
        }
    }

    Timer {
        id: toUnlock
        interval: 160
        onTriggered: {
            lockSession.locked = false;
            LockState.locked = false;
            veil.play();
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

    Veil {
        id: veil

        onFinished: {
            LockState.granted = false;
            LockState.typedText = "";
        }
    }

    WlSessionLock {
        id: lockSession
        locked: false

        WlSessionLockSurface {
            // The cursor is tracked inside the scene (for the parallax)
            LockScene {
                anchors.fill: parent
            }

            // Keyboard: there is no input box, the emblem is the feedback
            Item {
                focus: true
                Keys.onPressed: event => root.handleKey(event)
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
