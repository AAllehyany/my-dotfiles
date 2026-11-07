import Quickshell
import Quickshell.Io
import "features/launcher"
import "features/notifications"
import "features/lock"
import "features/gamedock"

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
    DockState { id: dock }
    GameDock { state: dock }
    // niri/scripts/game-layout places the dock in the strip under the game (output-logical pixels).
    IpcHandler {
        target: "gamedock"
        // Not named show/hide: `qs ipc call gamedock show` would parse `show` as the `qs ipc show` subcommand.
        function place(output: string, workspace: int, game: int, x: int, y: int, w: int, h: int): void {
            dock.show(output, workspace, game, x, y, w, h);
        }
        function remove(): void { dock.hide(); }
    }
    IpcHandler {
        target: "notifications"
        function open(): void { state.openNotifications(); }
    }
}
