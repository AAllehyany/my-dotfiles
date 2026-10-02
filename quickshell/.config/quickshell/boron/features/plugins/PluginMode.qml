import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool active: false
    property string query: ""
    property string modeId: ""
    property var modes: []
    property var results: []
    property bool loading: false
    property bool ready: false
    property bool actionRunning: false
    property bool mutationRunning: false
    property int sequence: 0
    property int currentRequest: -1
    property int actionRequest: -1
    property string actionMode: ""
    property var lastRow: null
    property string lastAction: ""
    property var filters: []
    property string filter: ""
    property string error: ""
    signal closeRequested()
    signal notice(string message)
    signal promptRequested(var prompt)
    onActiveChanged: { if (active) refresh(); else cancel(); }
    onQueryChanged: { if (active && !actionRunning) { cancel(); debounce.restart(); } }
    onModeIdChanged: { cancel(); results = []; filters = []; filter = ""; error = ""; if (active) refresh(); }
    onFilterChanged: { if (active) refresh(); }
    Timer { id: debounce; interval: 200; onTriggered: root.refresh() }
    Process {
        id: host
        command: ["python3", Quickshell.shellPath("features/plugins/host.py")]
        running: true
        stdinEnabled: true
        stdout: SplitParser { onRead: line => root.receive(line) }
        stderr: StdioCollector {}
        onExited: (code, status) => { root.ready = false; root.loading = false; root.actionRunning = false; root.error = root.mutationRunning ? "Plugin host stopped. Action outcome uncertain; verify service state before retrying." : "Plugin host stopped. Retry to restart."; root.mutationRunning = false; root.notice(root.error); }
    }
    function send(method, params) {
        if (!ready) return;
        currentRequest = ++sequence;
        host.write(JSON.stringify({id: currentRequest, mode: modeId, method: method, params: params || {}}) + "\n");
    }
    function refresh() {
        if (!active || !ready || !modeId || actionRunning) return;
        debounce.stop();
        error = ""; loading = true;
        send("query", {query: query, filter: filter});
    }
    function retry() {
        if (!host.running) { host.running = true; return; }
        error = ""; loading = true;
        send("retry", {query: query, filter: filter});
    }
    function cancel() {
        debounce.stop();
        if (ready && modeId) host.write(JSON.stringify({mode: modeId, method: "cancel"}) + "\n");
        if (!mutationRunning) { currentRequest = -1; actionRequest = -1; actionRunning = false; loading = false; }
    }
    function receive(line) {
        try {
            const message = JSON.parse(line);
            if (message.type === "registry") {
                modes = message.modes; ready = true;
                if (message.errors.length) notice(message.errors.join("; "));
                if (active) refresh();
                return;
            }
            const actionResponse = message.id === actionRequest && message.mode === actionMode;
            if (!actionResponse && (message.id !== currentRequest || message.mode !== modeId)) return;
            loading = false; actionRunning = false; mutationRunning = false;
            if (actionResponse) actionRequest = -1;
            if (message.error) { error = message.error; notice(error); return; }
            const result = message.result || {};
            if (actionResponse && (!active || message.mode !== modeId)) {
                if (result.message) notice(result.message);
                return;
            }
            if (result.items) results = result.items;
            if (result.filters) filters = result.filters;
            if (result.prompt && active) {
                const prompt = result.prompt;
                prompt.row = lastRow;
                prompt.action = result.prompt.action || lastAction;
                promptRequested(prompt);
            }
            if (result.message) notice(result.message);
            if (result.openUrl) {
                if (/^https?:\/\//.test(result.openUrl)) { Qt.openUrlExternally(result.openUrl); closeRequested(); }
            }
            if (result.refresh) refresh();
        } catch (e) { loading = false; actionRunning = false; error = "Invalid plugin host response."; notice(error); }
    }
    function activate(row, action, values) {
        if (loading || actionRunning) return;
        lastRow = row; lastAction = action || ((row.actions || [])[0] || {}).id || "open";
        loading = true; actionRunning = true; mutationRunning = !!(values && values.confirmed);
        send("activate", {item: row.id, action: lastAction, values: values || {}});
        actionRequest = currentRequest; actionMode = modeId;
    }
}
