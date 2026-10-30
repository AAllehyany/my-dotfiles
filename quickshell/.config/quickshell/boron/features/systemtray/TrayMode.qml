import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../../core/Search.js" as Search

Item {
    id: root
    property bool active: false
    property string query: ""
    property var menuStack: []
    property var menuHandle: null
    property string menuTitle: ""
    property var identities: new Map()
    property var items: SystemTray.items.values
    property alias quitLookup: quitMenu
    property var quitRow: null
    property var quitCommand: null
    readonly property bool loading: command.running || quitMenu.running
    property var results: {
        if (menuStack.length && opener.children) {
            return [{id: "back", title: "← Back", subtitle: menuTitle}].concat(opener.children.values
                .filter(e => !e.isSeparator).map(e => ({id: identity(e, "menu:"),
                    title: (e.checkState === Qt.Checked ? "✓ " : "") + e.text.replace(/&/g, ""),
                    subtitle: e.hasChildren ? "Submenu →" : "", icon: e.icon, entry: e, disabled: !e.enabled})));
        }
        const rows = items.map(e => ({id: identity(e, "tray:"),
            title: e.title || e.tooltipTitle || e.id, subtitle: e.tooltipDescription || "System tray",
            icon: e.icon, entry: e, group: "Tray", actions: [{id: "open", title: "Open"}].concat(e.hasMenu ? [{id: "menu", title: "Show menu"}] : [])}));
        rows.push({id: "sleep", title: "Sleep", subtitle: "Suspend this computer", group: "Power", icon: Quickshell.iconPath("system-suspend", true)},
            {id: "restart", title: "Restart", subtitle: "Restart this computer", group: "Power", icon: Quickshell.iconPath("system-reboot", true)},
            {id: "shutdown", title: "Shutdown", subtitle: "Power off this computer", group: "Power", icon: Quickshell.iconPath("system-shutdown", true)});
        return query ? Search.filter(rows, query) : rows;
    }
    signal closeRequested()
    signal notice(string message)
    signal promptRequested(var prompt)
    function identity(entry, prefix) {
        if (!identities.has(entry)) identities.set(entry, prefix + identities.size);
        return identities.get(entry);
    }
    QsMenuOpener { id: opener; menu: root.menuStack.length ? root.menuStack[root.menuStack.length - 1] : null }
    TrayQuitLookup {
        id: quitMenu
        onFound: entry => {
            if (!root.quitRow || !root.items.includes(root.quitRow.entry)) { root.cancelQuit(); return; }
            root.quitCommand = entry;
            root.promptRequested({title: "Quit " + root.quitRow.title + "?", description: "The application will be asked to quit.",
                submitLabel: "Quit", destructive: true, fields: [], row: root.quitRow, action: "quit"});
        }
        onUnavailable: { root.cancelQuit(); root.notice("No supported Quit or Exit action is available for this app."); }
    }
    Process {
        id: command
        stderr: StdioCollector { id: errors }
        onExited: (code, status) => { if (code !== 0) root.notice(errors.text || "Power action failed."); else root.closeRequested(); }
    }
    onActiveChanged: { if (!active) cancelQuit(); }
    onItemsChanged: {
        if (quitMenu.running && quitRow && !items.includes(quitRow.entry)) {
            cancelQuit();
            notice("The tray app is no longer available.");
        }
    }
    function cancelQuit() { quitMenu.cancel(); quitRow = null; quitCommand = null; }
    function cancel() { cancelQuit(); menuStack = []; menuHandle = null; }
    function requestQuit(row) {
        if (!row || row.disabled || !row.id.startsWith("tray:") || loading || menuStack.length) return;
        cancelQuit();
        if (!row.entry || !items.includes(row.entry)) { notice("The tray app is no longer available."); return; }
        if (!row.entry.hasMenu || !row.entry.menu) { notice("No supported Quit or Exit action is available for this app."); return; }
        quitRow = row;
        quitMenu.start(row.entry.menu, row.title);
    }
    function back() {
        if (!menuStack.length) return false;
        menuStack = menuStack.slice(0, -1);
        return true;
    }
    function activate(row, action, values) {
        if (action === "quit") {
            if (!(values && values.confirmed)) return;
            if (!row || row !== quitRow || !row.entry || !items.includes(row.entry) || !row.entry.hasMenu
                    || row.entry.menu !== quitMenu.menuRoot || !quitMenu.isAvailable(quitCommand)) {
                cancelQuit();
                notice("The app's Quit or Exit action is no longer available.");
                return;
            }
            quitCommand.triggered();
            cancelQuit();
            closeRequested();
            return;
        }
        if (row.disabled || command.running) return;
        cancelQuit();
        if (row.id === "back") { back(); return; }
        if (row.id.startsWith("menu:")) {
            if (row.entry.hasChildren) menuStack = menuStack.concat([row.entry]);
            else row.entry.triggered();
            return;
        }
        if (row.entry) {
            if (action === "menu" || row.entry.onlyMenu) {
                menuHandle = row.entry.menu;
                menuTitle = row.title;
                menuStack = [menuHandle];
            } else row.entry.activate();
            return;
        }
        if (row.id !== "sleep" && !(values && values.confirmed)) {
            promptRequested({title: row.title + " this computer?", description: "Save your work before continuing.",
                submitLabel: row.title, destructive: true, fields: [], row: row, action: "power"});
            return;
        }
        command.command = ["systemctl", row.id === "sleep" ? "suspend" : row.id === "restart" ? "reboot" : "poweroff"];
        command.running = true;
    }
}
