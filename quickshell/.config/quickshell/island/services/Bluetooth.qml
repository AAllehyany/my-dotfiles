pragma Singleton

import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool available:
        root.adapter !== null

    readonly property bool enabled:
        root.available && root.adapter.enabled

    readonly property bool discovering:
        root.available && root.adapter.discovering

    readonly property var devices: deviceModel

    ScriptModel {
        id: deviceModel

        values: root.adapter
            ? root.adapter.devices.values
                .slice()
                .sort((a, b) => {
                    if (a.connected !== b.connected)
                        return a.connected ? -1 : 1;

                    if (a.paired !== b.paired)
                        return a.paired ? -1 : 1;

                    return a.name.localeCompare(b.name);
                })
            : []
    }

    function setEnabled(enabled: bool): void {
        if (!root.adapter)
            return;

        if (root.adapter.enabled === enabled)
            return;

        root.adapter.enabled = enabled;
    }

    function setDiscovering(discovering: bool): void {
        if (!root.adapter)
            return;

        if (root.adapter.discovering === discovering)
            return;

        root.adapter.discovering = discovering;
    }

    function connectDevice(device): void {
        if (!device)
            return;

        device.connect();
    }

    function disconnectDevice(device): void {
        if (!device)
            return;

        device.disconnect();
    }

    function pairDevice(device): void {
        if (!device)
            return;

        device.pair();
    }

    function forgetDevice(device): void {
        if (!device || !device.paired)
            return;

        device.forget();
    }
}
