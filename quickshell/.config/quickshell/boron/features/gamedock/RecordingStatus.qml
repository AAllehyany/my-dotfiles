import QtQuick
import Quickshell
import Quickshell.Io

// OBS recording and streaming status from obs_status.py (obs-websocket), while `running`.
Scope {
    id: root
    property bool running: false

    property bool connected: false
    property string reason: "closed"   // why not connected: no-config, disabled, closed, auth
    property bool recording: false
    property bool recordPaused: false
    property real recordMs: 0
    property bool streaming: false
    property real streamMs: 0
    property bool reconnecting: false

    readonly property string offlineText: ({
        "no-config": "OBS NOT SET UP",
        "disabled": "OBS WEBSOCKET OFF",
        "auth": "OBS PASSWORD REJECTED",
        "closed": "OBS OFFLINE",
    })[reason] || "OBS OFFLINE"

    function apply(line) {
        let status;
        try { status = JSON.parse(line); } catch (e) { return; }
        connected = !!status.connected;
        if (!connected) {
            reason = status.reason || "closed";
            recording = streaming = recordPaused = reconnecting = false;
            recordMs = streamMs = 0;
            return;
        }
        recording = !!status.recording;
        recordPaused = !!status.recordPaused;
        recordMs = status.recordMs || 0;
        streaming = !!status.streaming;
        streamMs = status.streamMs || 0;
        reconnecting = !!status.reconnecting;
    }

    // 4000123 → "01:06:40"
    function clock(ms) {
        const total = Math.floor(ms / 1000);
        const pad = n => String(n).padStart(2, "0");
        return pad(Math.floor(total / 3600)) + ":" + pad(Math.floor(total / 60) % 60) + ":" + pad(total % 60);
    }

    Process {
        running: root.running
        command: ["python3", Quickshell.shellPath("features/gamedock/obs_status.py")]
        stdout: SplitParser { onRead: line => root.apply(line) }
    }
    // Stale status must not linger once the dock stops watching.
    onRunningChanged: if (!running) apply('{"connected":false,"reason":"closed"}')
}
