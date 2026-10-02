// Non-interactive state/integration-adapter tests. Never opens a launcher or executes system actions.
import QtQuick
import Quickshell
import Quickshell.Networking
import "features/launcher"

ShellRoot {
    LauncherState { id: state }
    QtObject {
        id: network
        property string name: "Test network"
        property bool connected: false
        property bool known: false
        property int security: WifiSecurityType.Wpa2Psk
        property string receivedPassword: ""
        property bool forgotten: false
        signal connectionFailed(int reason)
        function connectWithPsk(value) { receivedPassword = value; }
        function connect() { connected = true; }
        function disconnect() { connected = false; }
        function forget() { forgotten = true; }
    }
    function check(condition, message) { if (!condition) throw new Error("SMOKE FAILED: " + message); }
    Timer {
        interval: 500; running: true
        onTriggered: {
            check(state.modeId === "apps" && state.rows.length === 0, "compact application state");
            state.setQuery("@");
            check(state.completingMode && state.rows.some(r => r.title === "@wifi") && state.rows.some(r => r.title === "@bluetooth"), "at-sign shows device completions");
            state.setQuery("@WI");
            check(state.rows.length === 1 && state.rows[0].title === "@wifi", "case-insensitive completion");
            state.activate();
            check(state.modeId === "devices" && state.activeFilter === "wifi" && !state.completingMode && state.query === "", "completion enters Wi-Fi");
            state.setQuery("@blu");
            state.activate();
            check(state.activeFilter === "bluetooth" && state.query === "", "completion enters Bluetooth");
            state.setQuery("@unknown");
            state.activate();
            check(state.completingMode && !state.rows.length && state.query === "@unknown", "unknown completion cannot activate a device");
            state.goBack();
            check(!state.completingMode && state.modeId === "devices", "Escape dismisses completions");
            state.setQuery("@wifi office");
            check(state.activeFilter === "wifi" && state.query === "office", "full prefix still preserves search suffix");
            state.switchMode("github", "");
            state.setQuery("@wi");
            check(state.completingMode && !state.adapter.active && state.adapter.query === "", "completion does not query remote plugins");
            state.switchMode("apps", "");
            state.setQuery("terminal");
            check(state.query === "terminal", "query updated");
            state.goBack();
            check(state.query === "", "Escape clears query");
            state.showModes();
            check(state.pickingMode && state.rows.length >= 3, "mode picker");
            state.setQuery("Devices");
            check(state.rows[0].id === "devices", "picker search");
            state.activate(0);
            check(state.modeId === "devices" && !state.pickingMode, "mode activation");
            state.setQuery("@bluetooth headset");
            check(state.adapter.section === "bluetooth" && state.query === "headset", "device alias");
            check(state.filters.length === 2 && state.activeFilter === "bluetooth", "device tabs reflect prefix selection");
            check(!state.rows.some(r => r.id.startsWith("section:")), "device tabs are outside the results");
            const bluetoothContext = state.resultContext;
            state.chooseFilter("wifi");
            check(state.activeFilter === "wifi" && state.query === "", "device tab changes section and clears search");
            check(state.resultContext !== bluetoothContext, "tab changes reset the list context");
            state.chooseFilter("not-a-section");
            check(state.activeFilter === "wifi", "invalid device tab ignored");
            state.setQuery("network");
            state.cycleDeviceTab(1);
            check(state.modeId === "devices" && state.activeFilter === "bluetooth" && state.query === "", "keyboard switches device tabs and clears search");
            state.cycleDeviceTab(1);
            check(state.activeFilter === "wifi", "next device tab wraps");
            state.cycleDeviceTab(-1);
            check(state.activeFilter === "bluetooth", "previous device tab wraps");
            state.prompt = {title: "Pairing confirmation", fields: []};
            state.cycleDeviceTab(1);
            check(state.activeFilter === "bluetooth", "tab shortcuts do not dismiss prompts");
            state.prompt = null;
            state.showModes();
            state.cycleDeviceTab(1);
            check(state.activeFilter === "bluetooth", "tab shortcuts do not act inside mode picker");
            state.goBack();
            state.switchMode("tray", "");
            state.cycleDeviceTab(1);
            check(state.modeId === "tray", "device tab shortcut does not switch launcher modes");
            const restart = state.rows.findIndex(r => r.id === "restart");
            state.activate(restart);
            check(state.prompt && state.prompt.destructive, "power action requires confirmation");
            state.goBack();
            check(!state.prompt && !state.loading, "cancel does not run power action");
            state.switchMode("devices", "wifi");
            const row = {id: "mock", title: network.name, network: network};
            state.adapter.activate(row, "connect", {});
            check(state.prompt.fields[0].type === "password", "Wi-Fi password form");
            state.submit({password: "test-only-password"});
            check(network.receivedPassword === "test-only-password", "password delivered to adapter");
            network.connectionFailed(ConnectionFailReason.WifiAuthTimeout);
            check(state.message.indexOf("Wi-Fi:") === 0, "Wi-Fi failure feedback");
            state.adapter.activate(row, "forget", {});
            check(!network.forgotten && state.prompt, "forget requires confirmation");
            state.submit({});
            check(network.forgotten, "confirmed forget");
            state.switchMode("github", "");
            state.adapter.actionRunning = true;
            state.adapter.mutationRunning = false;
            state.adapter.cancel();
            check(!state.adapter.actionRunning, "cancel read-only plugin action");
            state.adapter.actionRunning = true;
            state.adapter.mutationRunning = true;
            state.adapter.actionRequest = 42;
            state.adapter.actionMode = "github";
            state.adapter.cancel();
            check(state.adapter.actionRunning, "keep submitted mutation alive");
            state.adapter.receive(JSON.stringify({id: 42, mode: "github", result: {message: "Fixture merge completed"}}));
            check(!state.adapter.actionRunning && state.pendingNotification.indexOf("Fixture merge completed") >= 0, "preserve background mutation outcome");
            state.close();
            check(!state.opened, "closed state");
            console.warn("STATE SMOKE PASSED");
            Qt.quit();
        }
    }
}
