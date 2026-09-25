import Quickshell
import Quickshell.Io

import qs.launcher

ShellRoot {
    Launcher {
        id: launcher
    }

    IpcHandler {
        target: "launcher"

        function open(): void {
            LauncherState.open();
        }

        function close(): void {
            LauncherState.close();
        }

        function toggle(): void {
            LauncherState.toggle();
        }
    }
}
