pragma Singleton

import QtQuick
import Quickshell

// A Pomodoro timer, a countdown timer and a stopwatch. It keeps running with the drawer closed.
Singleton {
    id: root

    property string mode: "pomodoro"        // pomodoro, timer, stopwatch
    property string phase: "work"           // work, short, long (pomodoro only)
    property bool running: false
    property real now: Date.now()
    property real endAt: 0
    property real startedAt: 0

    property int workMin: 25
    property int shortMin: 5
    property int longMin: 15
    property int timerMin: 10
    property bool autoStart: true
    property int completed: 0               // focus sessions finished so far

    property real pausedLeft: 25 * 60000
    property real pausedElapsed: 0

    readonly property bool countdown: mode !== "stopwatch"
    readonly property real total: mode === "timer" ? timerMin * 60000 : phaseMs(phase)
    readonly property real left: running ? Math.max(0, endAt - now) : pausedLeft
    readonly property real elapsed: running ? pausedElapsed + (now - startedAt) : pausedElapsed
    readonly property real shown: countdown ? left : elapsed
    readonly property real fraction: countdown ? (total > 0 ? 1 - left / total : 0) : (elapsed % 60000) / 60000
    readonly property bool active: running || (countdown ? pausedLeft < total : pausedElapsed > 0)
    readonly property int cycleCount: phase === "long" && completed > 0 ? 4 : completed % 4

    function phaseMs(p) {
        return (p === "work" ? workMin : (p === "short" ? shortMin : longMin)) * 60000;
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

    // Skip to the other kind of phase without counting it
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
            } else {
                phase = "work";
                notify("Break over", "Back to focus.");
            }
            pausedLeft = total;
            if (autoStart)
                start();
            else
                running = false;
        } else if (mode === "timer") {
            notify("Timer finished", timerMin + " minutes are up.");
            running = false;
            pausedLeft = total;
        }
    }

    function adjust(which, delta) {
        if (which === "work")
            workMin = Math.max(1, Math.min(120, workMin + delta));
        else if (which === "short")
            shortMin = Math.max(1, Math.min(60, shortMin + delta));
        else if (which === "long")
            longMin = Math.max(1, Math.min(90, longMin + delta));
        else if (which === "timer")
            timerMin = Math.max(1, Math.min(720, timerMin + delta));
        if (!running)
            pausedLeft = total;
    }

    function setTimerMinutes(m) {
        timerMin = m;
        if (!running)
            pausedLeft = total;
    }

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
