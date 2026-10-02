import QtQuick
import Quickshell
import "../../core/Search.js" as Search

Item {
    id: root
    property bool active: false
    property string query: ""
    readonly property bool loading: false
    readonly property var results: {
        const rows = DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
            id: e.id, title: e.name, subtitle: e.genericName || e.comment || "Application",
            keywords: [e.genericName, e.comment, (e.keywords || []).join(" ")].join(" "),
            icon: Quickshell.iconPath(e.icon, true), entry: e,
            actions: [{id: "launch", title: "Open application"}].concat(e.actions.map((a, i) => ({id: "desktop:" + i, title: a.name})))
        }));
        return Search.filter(rows, query);
    }
    signal closeRequested()
    signal notice(string message)
    signal promptRequested(var prompt)
    function activate(row, action, values) {
        const target = action && action.startsWith("desktop:") ? row.entry.actions[Number(action.slice(8))] : row.entry;
        // Quickshell 0.3.1 execute() ignores Terminal=true. Use the user's Kitty terminal explicitly.
        if (row.entry.runInTerminal)
            Quickshell.execDetached({command: ["kitty", "--"].concat(Array.from(target.command)), workingDirectory: row.entry.workingDirectory});
        else target.execute();
        closeRequested();
    }
    function cancel() {}
}
