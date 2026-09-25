pragma Singleton

import Quickshell

Singleton {
    property bool opened: false

    function open(): void {
        opened = true;
    }

    function close(): void {
        opened = false;
    }

    function toggle(): void {
        opened = !opened;
    }
}
