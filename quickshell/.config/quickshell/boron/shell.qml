import Quickshell
import Quickshell.Io
import "features/launcher"

ShellRoot {
    LauncherState { id: state }
    Launcher { state: state }
    IpcHandler {
        target: "launcher"
        function open(): void { state.open(); }
        function close(): void { state.close(); }
        function toggle(): void { state.toggle(); }
    }
}
