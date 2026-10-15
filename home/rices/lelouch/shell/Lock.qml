import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// The lock screen: a Wayland session lock whose surfaces are drawn by LockScene,
// authenticated through PAM. A screenshot of the desktop is taken just before locking,
// so the exit can fade from red into it and only then unlock, with no gap.
Scope {
    id: root

    property bool pendingLock: false

    function lock() {
        if (lockSession.locked || pendingLock)
            return;
        LockState.typedText = "";
        LockState.granted = false;
        LockState.busy = false;
        LockState.exiting = false;
        LockState.shotReady = false;
        LockState.status = "STATE YOUR WILL";
        LockState.locked = true;
        pendingLock = true;

        // One screenshot per screen; lock when they are done, or after a short wait
        const names = Array.from(Quickshell.screens).map(s => s.name);
        shotProc.command = ["sh", "-c", 'mkdir -p "$HOME/.cache/lelouch"; for o in "$@"; do grim -t jpeg -q 85 -o "$o" "$HOME/.cache/lelouch/lockshot-$o.jpg" & done; wait', "sh"].concat(names);
        shotProc.running = true;
        shotTimeout.restart();
    }

    function engage() {
        if (!pendingLock)
            return;
        pendingLock = false;
        shotTimeout.stop();
        lockSession.locked = true;
    }

    // Everything is put back to rest, and the screenshot is deleted
    function release() {
        lockSession.locked = false;
        LockState.locked = false;
        LockState.granted = false;
        LockState.exiting = false;
        LockState.shotReady = false;
        LockState.typedText = "";
        Quickshell.execDetached(["sh", "-c", 'rm -f "$HOME"/.cache/lelouch/lockshot-*.jpg']);
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
        toExit.start();
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

    Process {
        id: shotProc
        onExited: root.engage()
    }

    Timer {
        id: shotTimeout
        interval: 600
        onTriggered: root.engage()
    }

    // Success: the emblem flies in until the screen is solid red, then the red fades into the
    // screenshot of the desktop, and only then does the session unlock.
    Timer {
        id: toExit
        interval: 520
        onTriggered: {
            if (LockState.shotReady) {
                LockState.exiting = true;
                toRelease.interval = 760;
            } else {
                toRelease.interval = 40;
            }
            toRelease.start();
        }
    }

    Timer {
        id: toRelease
        onTriggered: root.release()
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

    WlSessionLock {
        id: lockSession
        locked: false

        WlSessionLockSurface {
            id: surface

            // The cursor is tracked inside the scene (for the parallax)
            LockScene {
                anchors.fill: parent
                outputName: surface.screen ? surface.screen.name : ""
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
