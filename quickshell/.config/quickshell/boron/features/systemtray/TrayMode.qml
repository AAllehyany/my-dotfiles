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
    readonly property bool loading: command.running
    property var results: {
        if (menuStack.length && opener.children) {
            return [{id: "back", title: "← Back", subtitle: menuTitle}].concat(opener.children.values
                .filter(e => !e.isSeparator).map(e => ({id: identity(e, "menu:"),
                    title: (e.checkState === Qt.Checked ? "✓ " : "") + e.text.replace(/&/g, ""),
                    subtitle: e.hasChildren ? "Submenu →" : "", icon: e.icon, entry: e, disabled: !e.enabled})));
        }
        const rows = SystemTray.items.values.map(e => ({id: identity(e, "tray:"),
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
    Process {
        id: command
        stderr: StdioCollector { id: errors }
        onExited: (code, status) => { if (code !== 0) root.notice(errors.text || "Power action failed."); else root.closeRequested(); }
    }
    function cancel() { menuStack = []; menuHandle = null; }
    function back() {
        if (!menuStack.length) return false;
        menuStack = menuStack.slice(0, -1);
        return true;
    }
    function activate(row, action, values) {
        if (row.disabled || command.running) return;
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
