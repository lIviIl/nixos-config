pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One snapshot of system statistics every 1.5 seconds, only while the command center is open.
Singleton {
    id: root

    readonly property int historyLength: 60

    // CPU
    property real cpuTotal: 0
    property var cpuCores: []
    property var cpuFreq: []
    property real cpuTemp: 0
    property var cpuCoreTemps: []
    property var cpuHistory: []

    // Memory
    property var mem: ({ total: 0, used: 0, buffers: 0, cached: 0, free: 0, active: 0, swapTotal: 0, swapUsed: 0 })
    property var memTop: []
    property var memHistory: []

    // GPU
    property bool gpuAvailable: false
    property real gpuBusy: 0
    property real gpuFreq: 0
    property real gpuMaxFreq: 0
    property var gpuHistory: []

    // Storage
    property var disks: []
    property real ioRead: 0
    property real ioWrite: 0
    property var ioReadHistory: []
    property var ioWriteHistory: []

    // Network
    property real netDown: 0
    property real netUp: 0
    property var netDownHistory: []
    property var netUpHistory: []
    property var addresses: []
    property string gateway: ""
    property real pingMs: -1
    property string publicIp: ""

    // Battery
    property var battery: ({ present: false })

    // Values from the previous sample, for rates
    property var prevCpu: ({})
    property real prevTime: 0
    property real prevRc6: -1
    property real prevRx: -1
    property real prevTx: -1
    property real prevIoR: -1
    property real prevIoW: -1

    function push(list, value) {
        const next = list.slice(-(historyLength - 1));
        next.push(value);
        return next;
    }

    function lookupPublicIp() {
        publicLookup.running = true;
    }

    function parse(text) {
        const sections = {};
        let current = "";
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.startsWith("@")) {
                current = line.slice(1);
                sections[current] = [];
            } else if (current !== "" && line.trim() !== "") {
                sections[current].push(line);
            }
        }
        return sections;
    }

    function updateCpu(statLines, freqLines, tempLines) {
        const cores = [];
        let total = 0;
        const next = {};
        for (let i = 0; i < statLines.length; i++) {
            const p = statLines[i].trim().split(/\s+/);
            const name = p[0];
            const v = p.slice(1, 9).map(Number);
            const idle = v[3] + v[4];
            let sum = 0;
            for (let j = 0; j < v.length; j++)
                sum += v[j];
            next[name] = [idle, sum];

            let usage = 0;
            const before = prevCpu[name];
            if (before) {
                const dTotal = sum - before[1];
                usage = dTotal > 0 ? 100 * (1 - (idle - before[0]) / dTotal) : 0;
            }
            if (name === "cpu")
                total = usage;
            else
                cores.push(usage);
        }
        prevCpu = next;

        cpuTotal = total;
        cpuCores = cores;
        cpuFreq = freqLines.map(l => Number(l) / 1000);
        cpuHistory = push(cpuHistory, total);

        let pkg = 0;
        const coreTemps = [];
        for (let i = 0; i < tempLines.length; i++) {
            const at = tempLines[i].lastIndexOf("=");
            const label = tempLines[i].slice(0, at);
            const temp = Number(tempLines[i].slice(at + 1)) / 1000;
            if (label.startsWith("Package"))
                pkg = temp;
            else
                coreTemps.push({ label: label, temp: temp });
        }
        cpuTemp = pkg;
        cpuCoreTemps = coreTemps;
    }

    function updateMem(memLines, topLines) {
        const m = {};
        for (let i = 0; i < memLines.length; i++) {
            const colon = memLines[i].indexOf(":");
            m[memLines[i].slice(0, colon)] = Number(memLines[i].slice(colon + 1).trim().split(/\s+/)[0]) * 1024;
        }
        const total = m.MemTotal || 0;
        const buffers = m.Buffers || 0;
        const cached = Math.max(0, (m.Cached || 0) + (m.SReclaimable || 0) - (m.Shmem || 0));
        const free = m.MemFree || 0;
        const active = Math.max(0, total - (m.MemAvailable || 0));
        mem = {
            total: total,
            used: Math.max(0, total - free - buffers - cached),
            buffers: buffers,
            cached: cached,
            free: free,
            active: active,
            swapTotal: m.SwapTotal || 0,
            swapUsed: Math.max(0, (m.SwapTotal || 0) - (m.SwapFree || 0))
        };
        memHistory = push(memHistory, total > 0 ? 100 * active / total : 0);

        memTop = topLines.map(l => {
            const t = l.trim();
            const sp = t.indexOf(" ");
            return { name: t.slice(sp + 1), bytes: Number(t.slice(0, sp)) * 1024 };
        });
    }

    function updateGpu(lines, dt) {
        gpuAvailable = lines.length > 0;
        if (!gpuAvailable)
            return;
        const g = {};
        for (let i = 0; i < lines.length; i++) {
            const eq = lines[i].indexOf("=");
            g[lines[i].slice(0, eq)] = Number(lines[i].slice(eq + 1));
        }
        gpuFreq = g.cur || 0;
        gpuMaxFreq = g.max || 0;
        if (prevRc6 >= 0 && dt > 0) {
            const idle = (g.rc6 - prevRc6) / (dt * 1000);
            gpuBusy = Math.max(0, Math.min(100, 100 * (1 - idle)));
        }
        prevRc6 = g.rc6 || 0;
        gpuHistory = push(gpuHistory, gpuBusy);
    }

    function updateStorage(dfLines, ioLines, dt) {
        disks = dfLines.map(l => {
            const p = l.trim().split(/\s+/);
            return { mount: p.slice(0, p.length - 2).join(" "), size: Number(p[p.length - 2]), used: Number(p[p.length - 1]) };
        }).filter(d => d.size > 0 && !d.mount.startsWith("/nix"));

        let r = 0;
        let w = 0;
        for (let i = 0; i < ioLines.length; i++) {
            const p = ioLines[i].trim().split(/\s+/);
            r += Number(p[1]);
            w += Number(p[2]);
        }
        r *= 512;
        w *= 512;
        if (prevIoR >= 0 && dt > 0) {
            ioRead = Math.max(0, (r - prevIoR) / dt);
            ioWrite = Math.max(0, (w - prevIoW) / dt);
        }
        prevIoR = r;
        prevIoW = w;
        ioReadHistory = push(ioReadHistory, ioRead);
        ioWriteHistory = push(ioWriteHistory, ioWrite);
    }

    function updateNet(netLines, ipLines, gwLines, dt) {
        const p = (netLines[0] || "0 0").trim().split(/\s+/);
        const rx = Number(p[0]);
        const tx = Number(p[1]);
        if (prevRx >= 0 && dt > 0) {
            netDown = Math.max(0, (rx - prevRx) / dt);
            netUp = Math.max(0, (tx - prevTx) / dt);
        }
        prevRx = rx;
        prevTx = tx;
        netDownHistory = push(netDownHistory, netDown);
        netUpHistory = push(netUpHistory, netUp);

        addresses = ipLines.map(l => {
            const q = l.trim().split(/\s+/);
            return { iface: q[0], addr: q[1] };
        });
        gateway = gwLines[0] ? gwLines[0].trim() : "";
    }

    function updateBattery(lines) {
        if (lines.length === 0) {
            battery = { present: false };
            return;
        }
        const b = { present: true, status: "Unknown" };
        for (let i = 0; i < lines.length; i++) {
            const eq = lines[i].indexOf("=");
            const k = lines[i].slice(0, eq);
            const v = lines[i].slice(eq + 1);
            b[k] = k === "status" ? v.trim() : Number(v);
        }
        b.watts = (b.power || 0) / 1000000;
        b.health = b.design > 0 ? 100 * b.full / b.design : 0;
        b.minutes = -1;
        if (b.watts > 0.5) {
            if (b.status === "Discharging")
                b.minutes = b.now / b.power * 60;
            else if (b.status === "Charging")
                b.minutes = (b.full - b.now) / b.power * 60;
        }
        battery = b;
    }

    function ingest(text) {
        const now = Date.now();
        const dt = prevTime > 0 ? (now - prevTime) / 1000 : 0;
        prevTime = now;

        const s = parse(text);
        updateCpu(s.stat || [], s.freq || [], s.temp || []);
        updateMem(s.mem || [], s.top || []);
        updateGpu(s.gpu || [], dt);
        updateStorage(s.df || [], s.io || [], dt);
        updateNet(s.net || [], s.ip || [], s.gw || [], dt);
        updateBattery(s.bat || []);
    }

    // Forget the previous sample when the drawer closes, so rates don't spike when it reopens
    Connections {
        target: Ui

        function onCenterOpenChanged() {
            if (!Ui.centerOpen) {
                root.prevTime = 0;
                root.prevCpu = {};
                root.prevRc6 = -1;
                root.prevRx = -1;
                root.prevIoR = -1;
            }
        }
    }

    Process {
        id: sampler
        command: ["lelouch-sysinfo"]
        stdout: StdioCollector {
            onStreamFinished: root.ingest(this.text)
        }
    }

    Timer {
        interval: 1500
        running: Ui.centerOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!sampler.running)
                sampler.running = true;
        }
    }

    // Gateway latency
    Process {
        id: pinger
        command: ["ping", "-c", "1", "-W", "1", root.gateway]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/time=([0-9.]+)/);
                root.pingMs = m ? Number(m[1]) : -1;
            }
        }
    }

    Timer {
        interval: 4000
        running: Ui.centerOpen && root.gateway !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!pinger.running)
                pinger.running = true;
        }
    }

    // Only runs when you click it: this contacts a third-party site
    Process {
        id: publicLookup
        command: ["curl", "-s", "--max-time", "5", "https://ifconfig.me"]
        stdout: StdioCollector {
            onStreamFinished: root.publicIp = this.text.trim()
        }
    }
}
