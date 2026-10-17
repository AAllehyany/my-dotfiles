import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Kept separate from the state/UI so fixtures cannot claim the desktop bus name.
Item {
    id: root
    required property var service
    NotificationServer {
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        inlineReplySupported: false
        onNotification: notification => root.service.receive(notification)
    }
    // This query never activates a dormant notification daemon.
    Process {
        id: ownership
        command: ["busctl", "--user", "--timeout=1", "--json=short", "call",
            "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
            "GetConnectionUnixProcessID", "s", "org.freedesktop.Notifications"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const pid = JSON.parse(text).data[0];
                    root.service.error = pid === Quickshell.processId ? "" : "Another notification daemon is active (PID " + pid + "). Stop it to receive notifications in Boron.";
                } catch (e) { root.service.error = "Could not check the desktop notification service."; }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.service.error = "Desktop notifications are unavailable. Check the session bus and Boron's logs.";
        }
    }
    Timer { interval: 300; running: true; onTriggered: ownership.running = true }
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: if (!ownership.running) ownership.running = true
    }
}
