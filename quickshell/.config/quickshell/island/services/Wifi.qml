pragma Singleton

import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property bool enabled:
        Networking.wifiEnabled

    readonly property bool hardwareEnabled:
        Networking.wifiHardwareEnabled

    readonly property var device:
        wifiDevices.values.length > 0
            ? wifiDevices.values[0]
            : null

    readonly property bool available:
        root.device !== null

    readonly property bool scanning:
        root.device !== null
            ? root.device.scannerEnabled
            : false

    readonly property var networks: networkModel

    readonly property var connectedNetwork: {
        if (!root.device)
            return null;

        return root.device.networks.values.find(
            network => network.connected
        ) ?? null;
    }

    readonly property string connectedName:
        root.connectedNetwork
            ? root.connectedNetwork.name
            : ""

    ScriptModel {
        id: wifiDevices

        values: Networking.devices.values.filter(
            device => device.type === DeviceType.Wifi
        )
    }

    ScriptModel {
        id: networkModel

        values: root.device
            ? root.device.networks.values
                .slice()
                .sort((a, b) => {
                    if (a.connected !== b.connected)
                        return a.connected ? -1 : 1;

                    return b.signalStrength - a.signalStrength;
                })
            : []
    }

    function setEnabled(enabled: bool): void {
        Networking.wifiEnabled = enabled;
    }

    function setScanning(scanning: bool): void {
        if (!root.device)
            return;

        if (root.device.scannerEnabled === scanning)
            return;

        root.device.scannerEnabled = scanning;
    }

    function connectNetwork(network): void {
        if (!network)
            return;

        network.connect();
    }

    function disconnectNetwork(network): void {
        if (!network)
            return;

        network.disconnect();
    }

    function forgetNetwork(network): void {
        if (!network || !network.known)
            return;

        network.forget();
    }

    function authKind(network): string {
        if (!network)
            return "unknown";

        switch (network.security) {
        case WifiSecurityType.Open:
        case WifiSecurityType.Owe:
            return "open";

        case WifiSecurityType.WpaPsk:
        case WifiSecurityType.Wpa2Psk:
        case WifiSecurityType.Sae:
            return "personal";

        case WifiSecurityType.WpaEap:
        case WifiSecurityType.Wpa2Eap:
        case WifiSecurityType.Wpa3SuiteB192:
            return "enterprise";

        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
        case WifiSecurityType.Leap:
            return "legacy";

        default:
            return "unknown";
        }
    }

    function supportsPsk(network): bool {
        return network
            && root.authKind(network) === "personal";
    }

    function needsPsk(network): bool {
        return network
            && !network.known
            && root.supportsPsk(network);
    }

    function needsEnterpriseAuth(network): bool {
        return network
            && !network.known
            && root.authKind(network) === "enterprise";
    }

    function needsLegacyAuth(network): bool {
        return network
            && !network.known
            && root.authKind(network) === "legacy";
    }

    function connectWithPsk(network, psk: string): void {
        if (!network || !root.supportsPsk(network))
            return;

        network.connectWithPsk(psk);
    }
}
