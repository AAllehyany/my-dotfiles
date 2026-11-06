import QtQuick
import Quickshell
import Quickshell.Io

// Asks the compositor which output has focus. Niri and Hyprland are supported; anything else
// (or no answer within 250 ms) resolves to "" so callers can fall back to the first screen.
Scope {
    id: root
    signal resolved(string name)
    property bool pending: false

    function command() {
        if (Quickshell.env("NIRI_SOCKET")) return ["niri", "msg", "--json", "focused-output"];
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) return ["hyprctl", "-j", "monitors"];
        return null;
    }

    // Niri prints one output object; Hyprland prints every monitor with a `focused` flag.
    function parse(text) {
        try {
            const data = JSON.parse(text);
            if (Array.isArray(data)) {
                const monitor = data.find(m => m && m.focused);
                return monitor && monitor.name ? monitor.name : "";
            }
            return data && data.name ? data.name : "";
        } catch (e) {
            return "";
        }
    }

    function query() {
        if (pending) return;
        pending = true;
        const cmd = command();
        if (!cmd) { finish(""); return; }
        proc.command = cmd;
        proc.running = true;
        timeout.restart();
    }

    function finish(name) {
        if (!pending) return;
        pending = false;
        timeout.stop();
        resolved(name);
    }

    Process {
        id: proc
        stdout: StdioCollector { onStreamFinished: root.finish(root.parse(text)) }
    }
    Timer { id: timeout; interval: 250; onTriggered: root.finish("") }
}
