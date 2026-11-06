import QtQuick
import Quickshell
import "../../core/Search.js" as Search

Item {
    id: root
    property var service: null
    property bool active: false
    property string query: ""
    readonly property bool loading: false
    readonly property var results: !service ? [] : service.history.filter(entry => {
        return !query.trim() || Search.score(entry.title, query) || Search.score(entry.body, query) || Search.score(entry.appName, query);
    }).map(entry => ({
        id: entry.notificationId, title: entry.title, subtitle: entry.body,
        icon: entry.image || iconSource(entry.appIcon), notification: true,
        appIcon: iconSource(entry.appIcon), unread: entry.unread, critical: entry.critical,
        metadata: entry.appName + " · " + Qt.formatDateTime(new Date(entry.receivedAt), "HH:mm"),
        actions: [{id: "default", title: "Open / dismiss"}].concat(Array.from(entry.actions)
            .filter(action => action.identifier !== "default" && action.identifier !== "inline-reply")
            .map(action => ({id: "app:" + action.identifier, title: action.text || action.identifier})))
            .concat([{id: "dismiss", title: "Dismiss", menuOnly: true}])
    }))
    signal closeRequested()
    signal notice(string message)
    signal promptRequested(var prompt)
    function iconSource(icon) {
        if (!icon) return "";
        if (icon.startsWith("/") || icon.includes(":")) return icon;
        return Quickshell.iconPath(icon, true);
    }
    function dismiss(row) { if (service && row) service.dismiss(row.id); }
    function requestClear() {
        if (!service || !service.history.length) return;
        const count = service.history.length;
        promptRequested({title: "Clear all notifications?", description: "Removes " + count + (count === 1 ? " notification" : " notifications") + " from history, including entries hidden by search.",
            submitLabel: "Clear all", destructive: true, fields: [], row: {id: "clear"}, action: "clear"});
    }
    function activate(row, action, values) {
        if (!service) return;
        if (action === "clear") { if (values && values.confirmed) service.clear(); return; }
        if (action === "dismiss") service.dismiss(row.id);
        else service.activate(row.id, action.startsWith("app:") ? action.slice(4) : "default");
    }
    function cancel() {}
}
