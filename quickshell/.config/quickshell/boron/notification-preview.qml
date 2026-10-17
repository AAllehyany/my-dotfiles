// Short, inert Wayland preview. Never claims the desktop notification service.
import QtQuick
import Quickshell
import "features/notifications"
import "features/launcher"
import "tests"

ShellRoot {
    id: preview
    property int step: 0
    NotificationService { id: service; centerVisible: state.notificationCenterVisible }
    LauncherState { id: state; notificationService: service }
    Launcher { id: center; state: state }
    ToastHost { id: toasts; service: service }
    Component { id: factory; FixtureNotification {} }
    function make(id, values) {
        service.receive(factory.createObject(preview, Object.assign({id: id}, values)), Quickshell.screens[0].name);
    }
    Timer {
        interval: 600; running: true; repeat: true
        onTriggered: {
            switch (preview.step++) {
            case 0:
                make(1, {summary: "Earlier notification", body: "Overflow is kept in history."});
                make(2, {summary: "Download complete", body: "The project archive is ready.", appName: "Files", image: "file://" + Quickshell.shellPath("tests/fixtures/notification-icon.svg")});
                make(3, {summary: "A message from the team", body: "A longer subtitle wraps onto two lines while keeping the card compact and readable.", appName: "Messages"});
                make(4, {summary: "Battery is running low", body: "Connect a power source to continue working.", appName: "Power", urgency: 2, image: "file:///tmp/boron-deliberately-missing-image.png", appIcon: "file://" + Quickshell.shellPath("tests/fixtures/notification-icon.svg")});
                break;
            case 1:
                if (toasts.instances.length !== 3) { console.error("Expected three toast windows"); Qt.exit(1); }
                for (let i = 0; i < toasts.instances.length; i++) {
                    const name = "/tmp/boron-toast-" + i + ".png";
                    toasts.instances[i].surface.grabToImage(result => result.saveToFile(name));
                }
                break;
            case 2: state.openNotifications(); break;
            case 3: center.surface.grabToImage(result => result.saveToFile("/tmp/boron-notification-center.png")); break;
            case 4: console.warn("NOTIFICATION PREVIEW PASSED"); Qt.quit();
            }
        }
    }
}
