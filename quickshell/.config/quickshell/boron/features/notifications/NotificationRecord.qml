import QtQuick
import Quickshell
import "../../theme"

// Own the popup deadline independently of delegates, layout changes and updates.
Scope {
    id: root
    required property var service
    required property var notification
    readonly property string notificationId: String(notification.id)
    property double receivedAt: Date.now()
    property bool unread: !notification.lastGeneration
    property string screenName: ""
    property bool toastVisible: false
    property bool exiting: false
    property bool initialized: false
    readonly property string title: notification.summary || notification.appName || "Notification"
    readonly property string body: notification.body || ""
    readonly property string appName: notification.appName || "Application"
    readonly property string image: notification.image || ""
    readonly property string appIcon: notification.appIcon || ""
    readonly property bool isTransient: !!notification.hints.transient
    readonly property bool critical: notification.urgency === 2
    readonly property var actions: notification.actions

    function show(output) {
        screenName = output;
        toastVisible = true;
        lifetime.restart();
    }
    function hide() {
        lifetime.stop();
        exit.stop();
        toastVisible = false;
    }
    function changed() { if (initialized) update.restart(); }
    Component.onCompleted: initialized = true
    Timer {
        id: update
        interval: 0
        onTriggered: {
            root.unread = true;
            root.receivedAt = Date.now();
            root.service.updated(root.notificationId);
        }
    }
    Timer {
        id: lifetime
        interval: Theme.toastDuration - Theme.motion
        onTriggered: { root.exiting = true; exit.start(); }
    }
    Timer {
        id: exit
        interval: Theme.motion
        onTriggered: root.service.hideToast(root.notificationId)
    }
    Connections {
        target: root.notification
        function onClosed(reason) { root.service.remove(root.notificationId); }
        function onSummaryChanged() { root.changed(); }
        function onBodyChanged() { root.changed(); }
        function onAppNameChanged() { root.changed(); }
        function onAppIconChanged() { root.changed(); }
        function onImageChanged() { root.changed(); }
        function onActionsChanged() { root.changed(); }
        function onUrgencyChanged() { root.changed(); }
        function onTransientChanged() { root.changed(); }
    }
}
