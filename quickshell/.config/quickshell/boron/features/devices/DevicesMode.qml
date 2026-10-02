import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import "../../core/Search.js" as Search

Item {
    id: root
    property bool active: false
    property string query: ""
    property string section: "wifi"
    readonly property var sections: [{id: "wifi", label: "Wi-Fi"}, {id: "bluetooth", label: "Bluetooth"}]
    readonly property string viewKey: section + ":" + (section === "wifi" ? (wifi ? wifi.name : "") : (bluetooth ? bluetooth.adapterId : ""))
    property string wifiAdapter: ""
    property string bluetoothAdapter: ""
    property var pendingNetwork: null
    property var pairingDevice: null
    property var pendingDevice: null
    property bool desiredConnection: true
    property bool agentReady: false
    readonly property bool loading: pairingDevice !== null
    readonly property var wifiAdapters: Networking.devices.values.filter(d => d.type === DeviceType.Wifi)
    readonly property var btAdapters: Bluetooth.adapters.values
    readonly property var wifi: wifiAdapters.find(d => d.name === wifiAdapter) || wifiAdapters[0] || null
    readonly property var bluetooth: btAdapters.find(d => d.adapterId === bluetoothAdapter) || btAdapters[0] || null
    property var results: {
        let rows = [];
        if (section === "wifi") {
            rows.push({id: "wifi:power", title: Networking.wifiEnabled ? "Turn Wi-Fi off" : "Turn Wi-Fi on",
                subtitle: Networking.wifiHardwareEnabled ? "Wireless radio" : "Hardware blocked", disabled: !Networking.wifiHardwareEnabled});
            wifiAdapters.forEach(d => rows.push({id: "wifi:adapter:" + d.name, title: d.name,
                subtitle: d === wifi ? "Selected adapter" : "Use this adapter", adapter: d}));
            if (!wifi) rows.push({id: "unavailable", title: "No Wi-Fi adapter", subtitle: "Check NetworkManager and your wireless hardware", disabled: true});
            if (wifi) {
                const networks = wifi.networks.values.map(n => ({id: "wifi:network:" + JSON.stringify([wifi.name, n.name, n.security]),
                    title: n.name || "Hidden network", subtitle: ConnectionState.toString(n.state) + " · " + WifiSecurityType.toString(n.security) + " · " + Math.round(n.signalStrength * 100) + "%",
                    network: n, disabled: n.stateChanging, icon: Quickshell.iconPath("network-wireless", true),
                    actions: [{id: "connect", title: n.connected ? "Disconnect" : "Connect"}]
                        .concat([WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(n.security) ? [{id: "password", title: "Connect with password…"}] : [])
                        .concat(n.known ? [{id: "forget", title: "Forget network"}] : [])}));
                rows = rows.concat(query ? Search.filter(networks, query) : networks.sort((a,b) => Number(b.network.connected) - Number(a.network.connected) || b.network.signalStrength - a.network.signalStrength));
            }
            rows.push({id: "wifi:settings", title: "Advanced network settings", subtitle: "Enterprise, certificates and hidden networks"});
        } else {
            btAdapters.forEach(d => rows.push({id: "bt:adapter:" + d.adapterId, title: d.name,
                subtitle: d === bluetooth ? "Selected adapter" : "Use this adapter", adapter: d}));
            if (!bluetooth) rows.push({id: "unavailable", title: "No Bluetooth adapter", subtitle: "Check BlueZ and your Bluetooth hardware", disabled: true});
            else {
                rows.push({id: "bt:power", title: bluetooth.enabled ? "Turn Bluetooth off" : "Turn Bluetooth on", subtitle: BluetoothAdapterState.toString(bluetooth.state)});
                const devices = bluetooth.devices.values.map(d => ({id: "bt:device:" + bluetooth.adapterId + ":" + d.address,
                    title: d.name || d.address, subtitle: d.pairing ? "Pairing…" : BluetoothDeviceState.toString(d.state) + (d.paired ? " · Paired" : " · Pair new device") + (d.batteryAvailable ? " · " + Math.round(d.battery * 100) + "%" : ""),
                    device: d, icon: Quickshell.iconPath(d.icon || "bluetooth", true), disabled: d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting,
                    actions: [{id: "connect", title: d.connected ? "Disconnect" : d.paired ? "Connect" : "Pair and connect"}].concat(d.paired ? [{id: "trust", title: d.trusted ? "Untrust" : "Trust"}, {id: "forget", title: "Forget device"}] : [])}));
                rows = rows.concat(query ? Search.filter(devices, query) : devices.sort((a,b) => Number(b.device.connected) - Number(a.device.connected) || Number(b.device.paired) - Number(a.device.paired) || a.title.localeCompare(b.title)));
            }
        }
        return query ? Search.filter(rows, query) : rows;
    }
    signal closeRequested()
    signal notice(string message)
    signal promptRequested(var prompt)
    signal promptDismissed()
    onActiveChanged: { scan(); if (!active) cancel(); }
    onSectionChanged: scan()
    onWifiChanged: scan()
    onBluetoothChanged: scan()
    Connections { target: Networking; function onWifiEnabledChanged() { root.scan(); } }
    Connections { target: root.bluetooth; function onEnabledChanged() { root.scan(); } }
    Connections {
        target: root.pendingNetwork
        function onConnectionFailed(reason) { wifiTimeout.stop(); root.notice("Wi-Fi: " + ConnectionFailReason.toString(reason)); root.pendingNetwork = null; }
        function onConnectedChanged() { if (root.pendingNetwork && root.pendingNetwork.connected) { wifiTimeout.stop(); root.notice("Connected to " + root.pendingNetwork.name); root.pendingNetwork = null; } }
    }
    Connections {
        target: root.pendingDevice
        function onConnectedChanged() {
            if (root.pendingDevice && root.pendingDevice.connected === root.desiredConnection) {
                bluetoothTimeout.stop();
                root.notice((root.desiredConnection ? "Connected to " : "Disconnected from ") + root.pendingDevice.name);
                root.pendingDevice = null;
            }
        }
    }
    Timer {
        id: wifiTimeout; interval: 30000
        onTriggered: { root.pendingNetwork = null; root.notice("Wi-Fi connection timed out. Check the password and network availability."); }
    }
    Timer {
        id: bluetoothTimeout; interval: 20000
        onTriggered: { root.pendingDevice = null; root.notice("Bluetooth connection did not complete. Check that the device is nearby and available."); }
    }
    Process {
        id: settings
        command: ["python3", "-c", "import shutil,subprocess,sys; p=shutil.which('nm-connection-editor'); sys.exit(subprocess.call([p]) if p else 127)"]
        onExited: (code, status) => { if (code !== 0) root.notice("Install nm-connection-editor to configure advanced networks."); }
    }
    Process {
        id: agent
        command: ["python3", Quickshell.shellPath("features/devices/pairing_agent.py")]
        stdinEnabled: true
        stdout: SplitParser { onRead: data => root.agentMessage(data) }
        stderr: StdioCollector {}
        onExited: (code, status) => {
            root.agentReady = false;
            if (root.pairingDevice) { root.notice("Bluetooth pairing service stopped. Try pairing again."); root.pairingDevice = null; root.promptDismissed(); }
        }
    }
    function scan() {
        wifiAdapters.forEach(d => d.scannerEnabled = active && section === "wifi" && d === wifi && Networking.wifiEnabled);
        btAdapters.forEach(d => d.discovering = active && section === "bluetooth" && d === bluetooth && d.enabled);
    }
    function cancel() {
        if (agent.running) agent.write(JSON.stringify({method: "cancel"}) + "\n");
        if (pairingDevice) pairingDevice.cancelPair();
        pairingDevice = null;
        pendingNetwork = null;
        pendingDevice = null;
        wifiTimeout.stop(); bluetoothTimeout.stop();
    }
    function agentMessage(line) {
        try {
            const msg = JSON.parse(line);
            if (msg.type === "ready") {
                agentReady = true;
                if (pairingDevice) agent.write(JSON.stringify({method: "pair", path: pairingDevice.dbusPath}) + "\n");
            } else if (msg.type === "prompt") {
                promptRequested({title: "Pair " + (pairingDevice ? pairingDevice.name : "Bluetooth device"), description: msg.message,
                    submitLabel: msg.field ? "Submit" : "Confirm", fields: msg.field ? [{id: "answer", label: msg.field, type: "text"}] : [],
                    row: {id: "bt:answer"}, action: "answer", displayOnly: !!msg.displayOnly});
            } else if (msg.type === "done") {
                promptDismissed();
                if (pairingDevice && !msg.error) { pairingDevice.trusted = true; connectBluetooth(pairingDevice, true); }
                pairingDevice = null;
                notice(msg.error || "Paired. Connecting…");
            } else if (msg.type === "error") {
                promptDismissed(); pairingDevice = null; notice(msg.message);
            }
        } catch (e) { notice("Pairing service returned an invalid response."); }
    }
    function connectBluetooth(device, connected) {
        pendingDevice = device; desiredConnection = connected;
        bluetoothTimeout.restart();
        if (connected) device.connect(); else device.disconnect();
        notice((connected ? "Connecting to " : "Disconnecting from ") + device.name + "…");
    }
    function activate(row, action, values) {
        if (row.disabled) return;
        if (row.id === "wifi:power") { Networking.wifiEnabled = !Networking.wifiEnabled; return; }
        if (row.id === "bt:power") { bluetooth.enabled = !bluetooth.enabled; return; }
        if (row.id.startsWith("wifi:adapter:")) { wifiAdapter = row.adapter.name; return; }
        if (row.id.startsWith("bt:adapter:")) { bluetoothAdapter = row.adapter.adapterId; return; }
        if (row.id === "wifi:settings") { settings.running = true; return; }
        if (row.id === "bt:answer") { agent.write(JSON.stringify({method: "answer", value: values.answer || ""}) + "\n"); return; }
        if (action === "forget" && !(values && values.confirmed)) {
            promptRequested({title: "Forget " + row.title + "?", description: "You will need to reconnect or pair again.", fields: [], submitLabel: "Forget", destructive: true, row: row, action: action});
            return;
        }
        if (row.network) {
            const n = row.network;
            if (action === "forget") { n.forget(); return; }
            if (n.connected && action !== "password") { n.disconnect(); return; }
            pendingNetwork = n;
            if (values && values.password) { wifiTimeout.restart(); n.connectWithPsk(values.password); notice("Connecting to " + n.name + "…"); }
            else if (action !== "password" && (n.known || n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe)) { wifiTimeout.restart(); n.connect(); notice("Connecting to " + n.name + "…"); }
            else if ([WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(n.security))
                promptRequested({title: "Connect to " + n.name, description: "Enter the network password.", submitLabel: "Connect", fields: [{id: "password", label: "Password", type: "password", required: true}], row: row, action: "connect"});
            else { notice("Configure this network in Advanced network settings."); settings.running = true; }
        } else if (row.device) {
            const d = row.device;
            if (action === "forget") d.forget();
            else if (action === "trust") d.trusted = !d.trusted;
            else if (d.connected) connectBluetooth(d, false);
            else if (d.paired) connectBluetooth(d, true);
            else {
                if (pairingDevice) return;
                pairingDevice = d;
                if (agentReady) agent.write(JSON.stringify({method: "pair", path: d.dbusPath}) + "\n");
                else agent.running = true;
            }
        }
    }
    Component.onDestruction: { cancel(); wifiAdapters.forEach(d => d.scannerEnabled = false); btAdapters.forEach(d => d.discovering = false); }
}
