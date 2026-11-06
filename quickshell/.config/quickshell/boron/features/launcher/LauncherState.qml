import QtQuick
import Quickshell
import Quickshell.Io
import "../applications"
import "../systemtray"
import "../devices"
import "../plugins"
import "../notifications"
import "../../core/Search.js" as Search

Item {
    id: root
    property bool opened: false
    property bool openPending: false
    property var notificationService: null
    readonly property bool notificationCenterVisible: opened && modeId === "notifications" && !pickingMode && !completingMode && !helpMode
    // Empty disables persistence (tests).
    property string historyPath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/boron/history.json"
    property string modeId: "apps"
    property string query: ""
    property bool pickingMode: false
    property bool helpMode: false
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
        {id: "devices", label: "Devices", aliases: ["wifi", "bluetooth"], aliasLabels: {wifi: "Devices · Wi-Fi", bluetooth: "Devices · Bluetooth"}},
        {id: "notifications", label: "Notifications", aliases: ["notifs"]}
    ].concat(plugins.modes)
    readonly property var mode: modes.find(m => m.id === modeId) || modes[0]
    readonly property var adapter: modeId === "apps" ? applications : modeId === "tray" ? tray : modeId === "devices" ? devices : modeId === "notifications" ? notifications : plugins
    readonly property bool isPlugin: adapter === plugins
    readonly property bool completingMode: !pickingMode && !helpMode && !prompt && Search.isModePrefix(query)
    readonly property bool browsing: !pickingMode && !helpMode && !completingMode && !prompt
    readonly property bool loading: !completingMode && adapter.loading
    readonly property bool actionRunning: isPlugin && plugins.actionRunning
    readonly property bool canQuitTray: modeId === "tray" && browsing
        && !actionRunning && !tray.loading && !tray.menuStack.length
        && !!(actionRow || rows[selectedIndex]) && (actionRow || rows[selectedIndex]).id.startsWith("tray:")
    readonly property var filters: modeId === "devices" ? devices.sections : isPlugin ? plugins.filters : []
    readonly property string activeFilter: modeId === "devices" ? devices.section : isPlugin ? plugins.filter : ""
    readonly property string resultContext: JSON.stringify([opened, modeId, query, pickingMode, actionRow ? actionRow.id : "", activeFilter, modeId === "devices" ? devices.viewKey : ""])
    readonly property string pluginError: isPlugin && !completingMode ? plugins.error : ""
    readonly property var rows: {
        // Help and picker keep their listed order until the user types.
        if (helpMode) return query.trim() ? Search.filter(helpRows(), query) : helpRows();
        if (completingMode) return Search.completions(query, modes);
        if (pickingMode) {
            const picks = modes.map((m, i) => ({id: m.id, title: m.label, subtitle: "@" + m.id + (i < 9 ? " · Ctrl+" + (i + 1) : ""), icon: ""}));
            return query.trim() ? Search.filter(picks, query) : picks;
        }
        if (actionRow) return (actionRow.actions || []).map(a => ({id: a.id, title: a.title, subtitle: actionRow.title, disabled: a.disabled || false}));
        return adapter.results;
    }
    readonly property var selectedRow: rows[selectedIndex] || null
    // The action Shift+Enter runs: the first non-default action not reserved for the menu.
    readonly property var secondaryAction: browsing && !actionRow && selectedRow && !selectedRow.disabled
        ? (selectedRow.actions || []).slice(1).find(a => !a.menuOnly && !a.disabled) || null : null
    readonly property bool canDismiss: browsing && !actionRunning && !!selectedRow
        && (modeId === "notifications" || (modeId === "apps" && !!selectedRow.recent))
    signal focusSearch()
    signal revealSelection()
    ApplicationsMode { id: applications; active: root.opened && root.modeId === "apps"; query: root.query; historyPath: root.historyPath }
    TrayMode { id: tray; active: root.opened && root.modeId === "tray"; query: root.query }
    DevicesMode { id: devices; active: root.opened && root.modeId === "devices"; query: root.query }
    PluginMode { id: plugins; active: root.opened && root.isPlugin && !root.completingMode; modeId: root.isPlugin ? root.modeId : ""; query: root.completingMode ? "" : root.query }
    NotificationsMode { id: notifications; service: root.notificationService; active: root.notificationCenterVisible; query: root.query }
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
    onResultContextChanged: { if (modeId === "tray" && tray.quitLookup.running) tray.cancelQuit(); }
    onSelectedIdChanged: {
        if (modeId === "tray" && tray.quitLookup.running && tray.quitRow
                && (actionRow || rows[selectedIndex] || {}).id !== tray.quitRow.id) tray.cancelQuit();
    }
    function open() {
        if (opened) { focusSearch(); return; }
        modeId = "apps"; query = ""; pickingMode = false; helpMode = false; actionRow = null; prompt = null; message = pendingNotification; pendingNotification = "";
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
        prompt = null; actionRow = null; pickingMode = false; helpMode = false; opened = false;
    }
    function toggle() { if (opened) close(); else open(); }
    function openNotifications() {
        if (actionRunning || prompt) return;
        if (!opened) open();
        switchMode("notifications", "");
    }
    function switchMode(id, section) {
        if (actionRunning) { message = "Wait for the current action to finish."; return; }
        adapter.cancel();
        prompt = null; actionRow = null; pickingMode = false; helpMode = false; query = ""; message = "";
        modeId = id;
        if (section) devices.section = section;
        selectedIndex = 0; selectedId = ""; focusSearch();
    }
    function setQuery(text) {
        if (actionRow) actionRow = null;
        const parsed = pickingMode || helpMode ? null : Search.prefix(text, modes);
        // New text selects the best match; live refreshes keep the selection by id.
        if (text !== query) { selectedIndex = 0; selectedId = ""; }
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
    function switchModeIndex(index) {
        if (index >= 0 && index < modes.length) switchMode(modes[index].id, "");
    }
    function cycle(delta) {
        const index = modes.findIndex(m => m.id === modeId);
        switchMode(modes[(index + delta + modes.length) % modes.length].id, "");
    }
    function showModes() {
        if (prompt || actionRunning) return;
        pickingMode = !pickingMode; helpMode = false; actionRow = null; query = ""; selectedIndex = 0; focusSearch();
    }
    function showHelp() {
        if (prompt) return;
        helpMode = !helpMode; pickingMode = false; actionRow = null; query = ""; selectedIndex = 0; selectedId = ""; focusSearch();
    }
    function showActions() {
        if (prompt || pickingMode || helpMode || actionRunning || completingMode) return;
        if (actionRow) actionRow = null;
        else if (rows[selectedIndex] && rows[selectedIndex].actions) { actionRow = rows[selectedIndex]; selectedIndex = 0; }
    }
    function quitTray() {
        if (!canQuitTray) return;
        message = "";
        tray.requestQuit(actionRow || rows[selectedIndex]);
    }
    function activate(index) {
        const row = rows[index === undefined ? selectedIndex : index];
        if (!row || row.disabled || prompt || actionRunning || helpMode) return;
        if (completingMode) { switchMode(row.modeId, row.section); return; }
        if (pickingMode) { switchMode(row.id, ""); return; }
        if (actionRow) {
            const source = actionRow; actionRow = null;
            adapter.activate(source, row.id, {});
        } else adapter.activate(row, ((row.actions || [])[0] || {}).id || "", {});
    }
    function activateSecondary() {
        if (!secondaryAction || actionRunning) return;
        adapter.activate(selectedRow, secondaryAction.id, {});
    }
    function dismissSelected() {
        if (!canDismiss) return;
        adapter.dismiss(actionRow || selectedRow);
        actionRow = null;
    }
    function clearNotifications() {
        if (modeId === "notifications" && browsing && !actionRunning) { actionRow = null; notifications.requestClear(); }
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
        else if (helpMode) { helpMode = false; query = ""; }
        else if (actionRow) actionRow = null;
        else if (pickingMode) { pickingMode = false; query = ""; }
        else if (modeId === "tray" && tray.back()) {}
        else if (query) query = "";
        else close();
    }
    // Backspace on an empty search: go up one level without closing the launcher.
    function stepBack() {
        if (prompt || actionRunning || query) return false;
        if (helpMode) helpMode = false;
        else if (actionRow) actionRow = null;
        else if (pickingMode) pickingMode = false;
        else if (modeId === "tray" && tray.back()) {}
        else if (modeId !== "apps") switchMode("apps", "");
        else return false;
        return true;
    }
    // Tray: Left/Right on an empty search leave or open a menu.
    function menuBack() {
        return modeId === "tray" && browsing && !actionRow && !query && tray.back();
    }
    function menuEnter() {
        const row = selectedRow;
        if (modeId !== "tray" || !browsing || actionRow || query || !row || row.disabled || !row.entry) return false;
        if (row.id.startsWith("menu:") && row.entry.hasChildren) { tray.activate(row, "", {}); return true; }
        if (row.id.startsWith("tray:") && row.entry.hasMenu) { tray.activate(row, "menu", {}); return true; }
        return false;
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
        } else { plugins.filter = id; selectedIndex = 0; selectedId = ""; }
        if (!keepFocus) focusSearch();
    }
    function cycleFilter(delta, keepFocus) {
        if (!filters.length || !browsing || actionRunning) return;
        const index = Math.max(0, filters.findIndex(tab => tab.id === activeFilter));
        chooseFilter(filters[(index + delta + filters.length) % filters.length].id, keepFocus);
    }
    function retry() { if (pluginError) plugins.retry(); }
    function helpRows() {
        const local = [];
        if (filters.length) local.push(["Ctrl+Tab · Alt+← →", "Next / previous tab"]);
        if (modeId === "apps") local.push(["Ctrl+D", "Remove the selected app from recent (empty search)"]);
        if (modeId === "tray") local.push(["Ctrl+Q", "Quit the selected tray app"], ["← → (empty search)", "Leave / open a submenu"]);
        if (modeId === "notifications") local.push(["Ctrl+D", "Dismiss the selected notification"], ["Ctrl+Shift+D", "Clear all notifications (asks first)"]);
        if (isPlugin) local.push(["Ctrl+R", "Retry after an error"]);
        const global = [
            ["↑ ↓ · Ctrl+N / P · Alt+J / K", "Move the selection"],
            ["Enter", "Run the selected result"],
            ["Shift+Enter", "Run the secondary action"],
            ["Alt+1–9", "Run the Nth visible result"],
            ["Ctrl+K", "Show all actions for the selection"],
            ["Page Up / Page Down", "Move by one page"],
            ["Home / End (empty search)", "First / last result"],
            ["Ctrl+1–9", "Switch to mode N"],
            ["Ctrl+M", "Searchable mode picker"],
            ["Ctrl+Page Up / Page Down", "Previous / next mode"],
            ["@mode Space", "Switch mode while typing"],
            ["Tab / Shift+Tab", "Move between search, tabs, results and buttons"],
            ["Backspace (empty search)", "Go up one level, then back to Applications"],
            ["Ctrl+Enter", "Submit a form or confirmation"],
            ["Escape", "Back, clear search, then close"],
            ["Ctrl+W · Shift+Escape", "Close immediately"],
            ["Ctrl+/ · F1", "Show or hide this list"]
        ];
        return local.map(k => k.concat([mode.label])).concat(global.map(k => k.concat(["Global"])))
            .map((k, i) => ({id: "help:" + i, title: k[0], subtitle: k[1], keywords: k[1] + " " + k[0], group: k[2], help: true}));
    }
}
