import QtQuick
import Quickshell
import Quickshell.Io

// Finds the image swaybg is showing by reading its arguments from /proc (NUL-separated, so paths
// with spaces survive). Keeps the last known path if swaybg isn't running.
Scope {
    id: root
    property string path: ""

    function parse(text) {
        const args = text.split("\n");
        for (let i = 0; i < args.length; i++) {
            const arg = args[i];
            if ((arg === "-i" || arg === "--image") && args[i + 1]) return args[i + 1];
            if (arg.startsWith("--image=")) return arg.slice(8);
            if (arg.startsWith("-i") && !arg.startsWith("--") && arg.length > 2) return arg.slice(2);
        }
        return "";
    }

    function refresh() {
        proc.running = false;
        proc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: proc
        command: ["sh", "-c", "for p in $(pgrep -x swaybg); do tr '\\0' '\\n' < /proc/$p/cmdline; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = root.parse(text);
                if (found) root.path = found;
            }
        }
    }
}
