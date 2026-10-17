import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"

Scope {
    id: root
    property bool centerVisible: false
    property var screens: Quickshell.screens
    property var entries: []
    property var pendingIds: []
    property string lastScreenName: ""
    property string error: ""
    readonly property var history: entries.filter(entry => !entry.isTransient)
    readonly property var toasts: entries.filter(entry => entry.toastVisible)
    readonly property int unreadCount: history.reduce((count, entry) => count + (entry.unread ? 1 : 0), 0)
    signal contentUpdated()

    // A string crosses QML engines without retaining objects from the old engine.
    PersistentProperties { id: timestamps; reloadableId: "notification-arrivals"; property string arrivals: "{}" }
    Component { id: recordFactory; NotificationRecord {} }
    Process {
        id: focusedOutput
        command: ["niri", "msg", "--json", "focused-output"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const output = JSON.parse(text);
                    if (output && root.screens.some(screen => screen.name === output.name)) root.lastScreenName = output.name;
                } catch (e) {}
            }
        }
        onExited: (code, status) => root.flushPending()
    }
    Timer {
        id: outputFallback
        interval: 250
        onTriggered: {
            root.flushPending();
            if (focusedOutput.running) focusedOutput.running = false;
        }
    }
    onCenterVisibleChanged: {
        if (centerVisible) {
            const pending = pendingIds;
            pendingIds = [];
            for (const id of pending) hideToast(id);
            for (const entry of toasts.slice()) hideToast(entry.notificationId);
        }
    }
    onScreensChanged: {
        const fallback = screens[0];
        for (const entry of toasts.slice()) {
            if (!screens.some(screen => screen.name === entry.screenName)) {
                if (fallback) entry.screenName = fallback.name;
                else hideToast(entry.notificationId);
            }
        }
        for (const screen of screens) trimStack(screen.name);
    }
    function find(id) { return entries.find(entry => entry.notificationId === String(id)); }
    function screenFor(name) { return screens.find(screen => screen.name === name) || screens[0] || null; }
    function capacity(name) {
        const screen = screenFor(name);
        return screen ? Math.max(1, Math.min(3, Math.floor((screen.height - Theme.toastMargin * 2 + Theme.toastSpacing) / (Theme.toastHeight + Theme.toastSpacing)))) : 0;
    }
    function receive(notification, output) {
        notification.tracked = true;
        if (find(notification.id)) return;
        const entry = recordFactory.createObject(root, {service: root, notification: notification});
        const arrivals = JSON.parse(timestamps.arrivals);
        if (notification.lastGeneration && arrivals[entry.notificationId]) entry.receivedAt = arrivals[entry.notificationId];
        arrivals[entry.notificationId] = entry.receivedAt;
        timestamps.arrivals = JSON.stringify(arrivals);
        entries = [entry].concat(entries);
        if (notification.lastGeneration || centerVisible) {
            const id = entry.notificationId;
            if (entry.isTransient) Qt.callLater(() => { if (find(id)) hideToast(id); });
            return;
        }
        if (output !== undefined) { showToast(entry.notificationId, output); return; }
        pendingIds = pendingIds.concat([entry.notificationId]);
        if (!focusedOutput.running) {
            lastScreenName = "";
            focusedOutput.running = true;
            outputFallback.restart();
        }
    }
    function flushPending() {
        outputFallback.stop();
        const pending = pendingIds;
        pendingIds = [];
        const screen = screenFor(lastScreenName);
        for (const id of pending) showToast(id, screen ? screen.name : "");
    }
    function showToast(id, output) {
        const entry = find(id);
        if (!entry) return;
        if (centerVisible || !screenFor(output)) { hideToast(id); return; }
        entry.show(screenFor(output).name);
        trimStack(entry.screenName);
    }
    function trimStack(output) {
        const stack = toasts.filter(entry => entry.screenName === output);
        for (const entry of stack.slice(capacity(output))) hideToast(entry.notificationId);
    }
    function hideToast(id) {
        const entry = find(id);
        if (!entry) return;
        entry.hide();
        if (entry.isTransient) { entry.notification.expire(); remove(id); }
    }
    function remove(id) {
        const entry = find(id);
        if (!entry) return;
        entry.hide();
        entries = entries.filter(value => value !== entry);
        pendingIds = pendingIds.filter(value => value !== String(id));
        const arrivals = JSON.parse(timestamps.arrivals);
        delete arrivals[String(id)];
        timestamps.arrivals = JSON.stringify(arrivals);
        entry.destroy();
    }
    function dismiss(id) {
        const entry = find(id);
        if (!entry) return;
        entry.notification.dismiss();
        remove(id);
    }
    function activate(id, actionId) {
        const entry = find(id);
        if (!entry) return;
        const action = Array.from(entry.actions).find(value => value.identifier === (actionId || "default"));
        // invoke() may synchronously close a non-resident notification.
        if (action) action.invoke();
        if (find(id)) dismiss(id);
    }
    function clear() { for (const entry of entries.slice()) dismiss(entry.notificationId); }
    function markVisibleRead(ids) {
        for (const id of ids) {
            const entry = find(id);
            if (entry) entry.unread = false;
        }
    }
    function updated(id) {
        const entry = find(id);
        if (entry) {
            const arrivals = JSON.parse(timestamps.arrivals);
            arrivals[String(id)] = entry.receivedAt;
            timestamps.arrivals = JSON.stringify(arrivals);
        }
        if (entry && entry.isTransient && !entry.toastVisible) hideToast(id);
        contentUpdated();
    }
}
