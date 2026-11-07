import QtQuick
import Quickshell
import Quickshell.Io

// CPU and NVIDIA GPU stats, refreshed every 2 seconds while `running`.
// CPU: /proc/stat deltas and the k10temp sensor. GPU: one long-running `nvidia-smi -l 2`.
Scope {
    id: root
    property bool running: false

    property real cpuPercent: 0
    property real cpuTemp: -1
    property bool hasGpu: true
    property real gpuPercent: 0
    property real gpuTemp: -1
    property real vramUsed: 0     // MiB
    property real vramTotal: 0    // MiB
    property real fanPercent: -1
    property real powerWatts: -1

    property var previousCpu: null

    // "cpu  user nice system idle iowait irq softirq steal ..." → busy percentage since the last line.
    function parseCpuLine(line) {
        const fields = line.trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 4 || fields.some(isNaN)) return;
        const idle = fields[3] + (fields[4] || 0);
        const total = fields.reduce((a, b) => a + b, 0);
        if (previousCpu) {
            const dTotal = total - previousCpu.total;
            const dIdle = idle - previousCpu.idle;
            if (dTotal > 0) cpuPercent = Math.max(0, Math.min(100, 100 * (dTotal - dIdle) / dTotal));
        }
        previousCpu = {total: total, idle: idle};
    }

    // nvidia-smi CSV: utilization, temperature, memory used, memory total, fan, power ("[N/A]" allowed).
    function parseGpuLine(line) {
        const values = line.split(",").map(v => parseFloat(v.trim()));
        if (values.length < 6 || isNaN(values[0])) return;
        gpuPercent = values[0];
        gpuTemp = isNaN(values[1]) ? -1 : values[1];
        vramUsed = isNaN(values[2]) ? 0 : values[2];
        vramTotal = isNaN(values[3]) ? 0 : values[3];
        fanPercent = isNaN(values[4]) ? -1 : values[4];
        powerWatts = isNaN(values[5]) ? -1 : values[5];
    }

    function handleCpuOutput(line) {
        if (line.startsWith("cpu ")) parseCpuLine(line);
        else if (line.startsWith("temp ")) {
            const milli = parseInt(line.slice(5));
            cpuTemp = isNaN(milli) ? -1 : milli / 1000;
        }
    }

    Process {
        running: root.running
        command: ["sh", "-c",
            "t=; for h in /sys/class/hwmon/hwmon*; do [ \"$(cat \"$h/name\" 2>/dev/null)\" = k10temp ] && t=\"$h/temp1_input\"; done; " +
            "while :; do head -n1 /proc/stat; [ -n \"$t\" ] && echo \"temp $(cat \"$t\")\"; sleep 2; done"]
        stdout: SplitParser { onRead: line => root.handleCpuOutput(line) }
    }

    Process {
        running: root.running && root.hasGpu
        command: ["nvidia-smi",
            "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,fan.speed,power.draw",
            "--format=csv,noheader,nounits", "-l", "2"]
        stdout: SplitParser { onRead: line => root.parseGpuLine(line) }
        onExited: code => { if (code !== 0) root.hasGpu = false; }
    }
}
