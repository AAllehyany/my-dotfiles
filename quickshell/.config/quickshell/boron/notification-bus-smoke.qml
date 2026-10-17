// Launched only by test_notifications_bus.py, on its private session bus.
import QtQuick
import Quickshell
import Quickshell.Io
import "features/notifications"

ShellRoot {
    NotificationService { id: service }
    NotificationBackend { service: service }
    IpcHandler {
        target: "notificationTest"
        function snapshot(): string {
            return JSON.stringify({error: service.error, unread: service.unreadCount,
                entries: service.entries.map(entry => ({id: Number(entry.notificationId), title: entry.title,
                    body: entry.body, toast: entry.toastVisible, unread: entry.unread, image: entry.image, receivedAt: entry.receivedAt,
                    exiting: entry.exiting, transientHint: entry.isTransient,
                    actions: Array.from(entry.actions).map(action => action.identifier)}))});
        }
        function activate(id: string, action: string): void { service.activate(id, action); }
        function dismiss(id: string): void { service.dismiss(id); }
        function clear(): void { service.clear(); }
        function center(visible: bool): void { service.centerVisible = visible; }
        function reload(): void { Quickshell.reload(false); }
        function quit(): void { Qt.quit(); }
    }
}
