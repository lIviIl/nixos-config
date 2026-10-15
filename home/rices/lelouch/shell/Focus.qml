pragma Singleton

import QtQuick
import Quickshell

// A Pomodoro timer, a countdown timer and a stopwatch. It keeps running with every window closed.
// Lengths are in seconds. The state resets when the shell restarts.
Singleton {
    id: root

    property string mode: "pomodoro"        // pomodoro, timer, stopwatch
    property string phase: "work"           // work, short, long (pomodoro only)
    property bool running: false
    property real now: Date.now()
    property real endAt: 0
    property real startedAt: 0

    property int workSec: 25 * 60
    property int shortSec: 5 * 60
    property int longSec: 15 * 60
    property int timerSec: 10 * 60

    property bool autoStart: true
    property bool sound: true
    property int completed: 0               // focus sessions finished so far

    property real pausedLeft: 0             // ms
    property real pausedElapsed: 0          // ms

    readonly property bool countdown: mode !== "stopwatch"
    readonly property real total: (mode === "timer" ? timerSec : phaseSec(phase)) * 1000
    readonly property real left: running ? Math.max(0, endAt - now) : pausedLeft
    readonly property real elapsed: running ? pausedElapsed + (now - startedAt) : pausedElapsed
    readonly property real shown: countdown ? left : elapsed
    readonly property real fraction: countdown ? (total > 0 ? 1 - left / total : 0) : (elapsed % 60000) / 60000
    readonly property bool active: running || (countdown ? pausedLeft < total : pausedElapsed > 0)
    readonly property int cycleCount: phase === "long" ? 4 : completed % 4

    readonly property string title: mode === "pomodoro" ? "POMODORO" : (mode === "timer" ? "TIMER" : "STOPWATCH")
    readonly property string phaseLabel: mode !== "pomodoro" ? "" : (phase === "work" ? "FOCUS" : (phase === "short" ? "SHORT BREAK" : "LONG BREAK"))

    function phaseSec(p) {
        return p === "work" ? workSec : (p === "short" ? shortSec : longSec);
    }

    function chime(kind) {
        if (sound)
            Quickshell.execDetached(["lelouch-chime", kind]);
    }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Focus", title, body]);
    }

    function resetTime() {
        running = false;
        pausedElapsed = 0;
        pausedLeft = total;
    }

    function setMode(m) {
        if (m === mode)
            return;
        running = false;
        mode = m;
        phase = "work";
        completed = 0;
        resetTime();
    }

    function start() {
        now = Date.now();
        if (countdown) {
            if (pausedLeft <= 0)
                pausedLeft = total;
            endAt = now + pausedLeft;
        } else {
            startedAt = now;
        }
        running = true;
    }

    function pause() {
        now = Date.now();
        if (countdown)
            pausedLeft = Math.max(0, endAt - now);
        else
            pausedElapsed = pausedElapsed + (now - startedAt);
        running = false;
    }

    function toggle() {
        if (running)
            pause();
        else
            start();
    }

    // Move to the other kind of phase without counting the session
    function skip() {
        if (mode !== "pomodoro")
            return;
        phase = phase === "work" ? "short" : "work";
        resetTime();
    }

    function finish() {
        if (mode === "pomodoro") {
            if (phase === "work") {
                completed = completed + 1;
                const long = completed % 4 === 0;
                phase = long ? "long" : "short";
                notify("Focus session complete", long ? "Take a long break." : "Take a short break.");
                chime("done");
            } else {
                phase = "work";
                notify("Break over", "Back to focus.");
                chime("break");
            }
            pausedLeft = total;
            if (autoStart)
                start();
            else
                running = false;
        } else if (mode === "timer") {
            notify("Timer finished", Fmt.hms(timerSec) + " is up.");
            chime("alarm");
            running = false;
            pausedLeft = total;
        }
    }

    // Set the length of one of: work, short, long, timer (in seconds)
    function setLength(which, seconds) {
        const s = Math.max(5, Math.min(12 * 3600, Math.round(seconds)));
        if (which === "work")
            workSec = s;
        else if (which === "short")
            shortSec = s;
        else if (which === "long")
            longSec = s;
        else if (which === "timer")
            timerSec = s;
        if (!running)
            pausedLeft = total;
    }

    Component.onCompleted: pausedLeft = total

    Timer {
        interval: 200
        running: root.running
        repeat: true
        onTriggered: {
            root.now = Date.now();
            if (root.countdown && root.now >= root.endAt)
                root.finish();
        }
    }
}
