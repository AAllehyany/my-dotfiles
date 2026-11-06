import QtQuick
import Quickshell
import "../../core/Search.js" as Search
import "../../core/Frecency.js" as Frecency

Item {
    id: root
    property bool active: false
    property string query: ""
    property string historyPath: ""
    property alias history: launches
    readonly property bool loading: false
    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    readonly property var results: {
        const now = Date.now();
        const history = launches.history;
        if (!query.trim()) {
            const byId = new Map(entries.map(e => [e.id, e]));
            return Frecency.top(history, entries.map(e => e.id), 8, now).map(id => row(byId.get(id), true));
        }
        // Frequent apps rank higher, capped so match quality still dominates.
        return Search.filter(entries.map(e => row(e, false)), query, r => Math.min(400, Frecency.score(history[r.id], now) * 40));
    }
    signal closeRequested()
    signal notice(string message)
    signal promptRequested(var prompt)
    LaunchHistory { id: launches; path: root.historyPath }
    function row(e, recent) {
        return {
            id: e.id, title: e.name, subtitle: e.genericName || e.comment || "Application",
            keywords: [e.genericName, e.comment, (e.keywords || []).join(" ")].join(" "),
            icon: Quickshell.iconPath(e.icon, true), entry: e, recent: recent, group: recent ? "Recent" : "",
            actions: [{id: "launch", title: "Open application"}]
                .concat(e.actions.map((a, i) => ({id: "desktop:" + i, title: a.name})))
                .concat(recent ? [{id: "forget", title: "Remove from recent", menuOnly: true}] : [])
        };
    }
    function dismiss(row) { if (row && row.recent) launches.forget(row.id); }
    function activate(row, action, values) {
        if (action === "forget") { launches.forget(row.id); return; }
        const target = action && action.startsWith("desktop:") ? row.entry.actions[Number(action.slice(8))] : row.entry;
        launches.record(row.id);
        // Quickshell 0.3.1 execute() ignores Terminal=true. Use the user's Kitty terminal explicitly.
        if (row.entry.runInTerminal)
            Quickshell.execDetached({command: ["kitty", "--"].concat(Array.from(target.command)), workingDirectory: row.entry.workingDirectory});
        else target.execute();
        closeRequested();
    }
    function cancel() {}
}
