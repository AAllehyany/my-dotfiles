import QtQuick
import Quickshell
import Quickshell.Io
import "../applications"
import "../systemtray"
import "../devices"
import "../plugins"
import "../../core/Search.js" as Search

Item {
    id: root
    property bool opened: false
    property bool openPending: false
    property string modeId: "apps"
    property string query: ""
    property bool pickingMode: false
    property var actionRow: null
    property var prompt: null
    property string message: ""
    property string pendingNotification: ""
    property int selectedIndex: 0
    property string selectedId: ""
    property var targetScreen: Quickshell.screens[0] || null
    readonly property var modes: [
        {id: "apps", label: "Applications", aliases: []},
        {id: "tray", label: "System Tray", aliases: []},
        {id: "devices", label: "Devices", aliases: ["wifi", "bluetooth"], aliasLabels: {wifi: "Devices · Wi-Fi", bluetooth: "Devices · Bluetooth"}}
    ].concat(plugins.modes)
    readonly property var mode: modes.find(m => m.id === modeId) || modes[0]
    readonly property var adapter: modeId === "apps" ? applications : modeId === "tray" ? tray : modeId === "devices" ? devices : plugins
    readonly property bool isPlugin: adapter === plugins
    readonly property bool completingMode: !pickingMode && !prompt && Search.isModePrefix(query)
    readonly property bool loading: !completingMode && adapter.loading
    readonly property bool actionRunning: isPlugin && plugins.actionRunning
    readonly property var filters: modeId === "devices" ? devices.sections : isPlugin ? plugins.filters : []
    readonly property string activeFilter: modeId === "devices" ? devices.section : isPlugin ? plugins.filter : ""
    readonly property string resultContext: JSON.stringify([opened, modeId, query, pickingMode, actionRow ? actionRow.id : "", activeFilter, modeId === "devices" ? devices.viewKey : ""])
    readonly property string pluginError: isPlugin && !completingMode ? plugins.error : ""
    readonly property var rows: {
        if (completingMode) return Search.completions(query, modes);
        if (pickingMode) return Search.filter(modes.map(m => ({id: m.id, title: m.label, subtitle: "@" + m.id, icon: ""})), query);
        if (actionRow) return (actionRow.actions || []).map(a => ({id: a.id, title: a.title, subtitle: actionRow.title, disabled: a.disabled || false}));
        if (modeId === "apps" && !query.trim()) return [];
        return adapter.results;
    }
    signal focusSearch()
    signal revealSelection()
    ApplicationsMode { id: applications; active: root.opened && root.modeId === "apps"; query: root.query }
    TrayMode { id: tray; active: root.opened && root.modeId === "tray"; query: root.query }
    DevicesMode { id: devices; active: root.opened && root.modeId === "devices"; query: root.query }
    PluginMode { id: plugins; active: root.opened && root.isPlugin && !root.completingMode; modeId: root.isPlugin ? root.modeId : ""; query: root.completingMode ? "" : root.query }
    Connections {
        target: root.adapter
        function onCloseRequested() { root.close(); }
        function onNotice(text) { root.message = text; }
        function onPromptRequested(value) { root.prompt = value; }
    }
    Connections {
        target: plugins
        function onNotice(text) {
            if (!root.opened) root.pendingNotification = "GitHub / plugin: " + text;
            else if (root.adapter !== plugins) root.message = "GitHub / plugin: " + text;
        }
    }
    Connections {
        target: devices
        function onPromptDismissed() { if (root.modeId === "devices") { root.prompt = null; root.focusSearch(); } }
    }
    Process {
        id: focusedOutput
        command: ["niri", "msg", "--json", "focused-output"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const output = JSON.parse(text);
                    if (output) root.targetScreen = Quickshell.screens.find(s => s.name === output.name) || root.targetScreen;
                } catch (e) {}
            }
        }
        onExited: (code, status) => { if (root.openPending) { root.opened = true; root.openPending = false; root.focusSearch(); } }
    }
    Timer { id: openFallback; interval: 250; onTriggered: { if (root.openPending) { root.opened = true; root.focusSearch(); } } }
    onOpenedChanged: { if (opened) openFallback.stop(); }
    onRowsChanged: {
        selectedIndex = Search.retainedIndex(rows, selectedId, selectedIndex);
        selectedId = rows.length ? rows[selectedIndex].id : "";
    }
    function open() {
        if (opened) { focusSearch(); return; }
        modeId = "apps"; query = ""; pickingMode = false; actionRow = null; prompt = null; message = pendingNotification; pendingNotification = "";
        openPending = true;
        targetScreen = Quickshell.screens.find(s => s === targetScreen) || Quickshell.screens[0] || null;
        focusedOutput.running = true;
        openFallback.restart();
    }
    function close() {
        openPending = false;
        openFallback.stop();
        if (focusedOutput.running) focusedOutput.running = false;
        adapter.cancel();
        prompt = null; actionRow = null; pickingMode = false; opened = false;
    }
    function toggle() { if (opened) close(); else open(); }
    function switchMode(id, section) {
        if (actionRunning) { message = "Wait for the current action to finish."; return; }
        adapter.cancel();
        prompt = null; actionRow = null; pickingMode = false; query = ""; message = "";
        modeId = id;
        if (section) devices.section = section;
        selectedIndex = 0; selectedId = ""; focusSearch();
    }
    function setQuery(text) {
        if (actionRow) actionRow = null;
        const parsed = pickingMode ? null : Search.prefix(text, modes);
        if (parsed) { switchMode(parsed.id, parsed.section); query = parsed.query; }
        else query = text;
        message = "";
    }
    function move(delta) {
        if (!rows.length || prompt) return;
        selectResult((selectedIndex + delta + rows.length) % rows.length);
    }
    function selectResult(index) {
        if (!rows.length || prompt) return;
        selectedIndex = Math.max(0, Math.min(rows.length - 1, index));
        selectedId = rows[selectedIndex].id;
        revealSelection();
    }
    function cycle(delta) {
        const index = modes.findIndex(m => m.id === modeId);
        switchMode(modes[(index + delta + modes.length) % modes.length].id, "");
    }
    function showModes() {
        if (prompt || actionRunning) return;
        pickingMode = !pickingMode; actionRow = null; query = ""; selectedIndex = 0; focusSearch();
    }
    function showActions() {
        if (prompt || pickingMode || actionRunning || completingMode) return;
        if (actionRow) actionRow = null;
        else if (rows[selectedIndex] && rows[selectedIndex].actions) { actionRow = rows[selectedIndex]; selectedIndex = 0; }
    }
    function activate(index) {
        const row = rows[index === undefined ? selectedIndex : index];
        if (!row || row.disabled || prompt || actionRunning) return;
        if (completingMode) { switchMode(row.modeId, row.section); return; }
        if (pickingMode) { switchMode(row.id, ""); return; }
        if (actionRow) {
            const source = actionRow; actionRow = null;
            adapter.activate(source, row.id, {});
        } else adapter.activate(row, ((row.actions || [])[0] || {}).id || "", {});
    }
    function submit(values) {
        if (!prompt || actionRunning) return;
        const current = prompt;
        prompt = null;
        adapter.activate(current.row, current.action, Object.assign({}, current.context || {}, values, {confirmed: true}));
        focusSearch();
    }
    function goBack() {
        if (prompt) { prompt = null; adapter.cancel(); focusSearch(); }
        else if (completingMode) { query = ""; focusSearch(); }
        else if (actionRow) actionRow = null;
        else if (pickingMode) { pickingMode = false; query = ""; }
        else if (modeId === "tray" && tray.back()) {}
        else if (query) query = "";
        else close();
    }
    function chooseFilter(id, keepFocus) {
        if (actionRunning || prompt || pickingMode || id === activeFilter) return;
        actionRow = null;
        if (modeId === "devices") {
            if (!devices.sections.some(tab => tab.id === id)) return;
            devices.cancel();
            query = ""; message = "";
            devices.section = id;
            selectedIndex = 0;
            selectedId = rows.length ? rows[0].id : "";
        } else plugins.filter = id;
        if (!keepFocus) focusSearch();
    }
    function cycleDeviceTab(delta, keepFocus) {
        if (modeId !== "devices" || pickingMode || prompt || actionRunning) return;
        const index = filters.findIndex(tab => tab.id === activeFilter);
        chooseFilter(filters[(index + delta + filters.length) % filters.length].id, keepFocus);
    }
    function retry() { plugins.retry(); }
}
