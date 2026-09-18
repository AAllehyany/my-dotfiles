import Quickshell
import "core"
import "features/commandcenter"

Scope {
    // Keeping this Scope alive makes IPC available even while the surface is hidden.
    CommandCenter { }

    IpcHandler {
        target: "commandCenter"
        function toggle(): void { CommandCenterState.toggle() }
        function open(): void { CommandCenterState.open() }
        function close(): void { CommandCenterState.close() }
    }
}
