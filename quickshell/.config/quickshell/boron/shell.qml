import Quickshell
import Quickshell.Io
import "features/launcher"
import "features/notifications"

ShellRoot {
    NotificationService { id: notifications; centerVisible: state.notificationCenterVisible }
    NotificationBackend { service: notifications }
    LauncherState { id: state; notificationService: notifications }
    Launcher { state: state }
    ToastHost { service: notifications }
    IpcHandler {
        target: "launcher"
        function open(): void { state.open(); }
        function close(): void { state.close(); }
        function toggle(): void { state.toggle(); }
    }
    IpcHandler {
        target: "notifications"
        function open(): void { state.openNotifications(); }
    }
}
