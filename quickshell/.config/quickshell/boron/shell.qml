import Quickshell
import Quickshell.Io
import "features/launcher"
import "features/notifications"
import "features/lock"

ShellRoot {
    Lock { id: lockScreen }
    // Locking only: the password is the only way to unlock.
    IpcHandler {
        target: "lock"
        function lock(): void { lockScreen.lock(); }
    }
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
