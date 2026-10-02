// Visual smoke test: fixture data only, no device, power, or network actions.
import QtQuick
import Quickshell
import "features/launcher"

ShellRoot {
    id: test
    property int step: 0
    Item {
        id: fixture
        property bool opened: true
        property var targetScreen: Quickshell.screens[0]
        property string query: ""
        property string modeId: "apps"
        property var mode: ({label: "Applications"})
        property var rows: []
        property var filters: []
        property string activeFilter: ""
        property string pluginError: ""
        property var prompt: null
        property bool actionRunning: false
        property bool pickingMode: false
        property bool completingMode: false
        property bool loading: false
        property string message: ""
        property int selectedIndex: 0
        property string selectedId: ""
        readonly property string resultContext: JSON.stringify([modeId, query, activeFilter])
        signal focusSearch()
        signal revealSelection()
        function close() { Qt.quit(); }
        function setQuery(text) { query = text; }
        function activate(index) {}
        function showModes() {}
        function showActions() {}
        function move(delta) { selectedIndex = Math.max(0, Math.min(rows.length - 1, selectedIndex + delta)); revealSelection(); }
        function selectResult(index) { selectedIndex = Math.max(0, Math.min(rows.length - 1, index)); revealSelection(); }
        function cycle(delta) {}
        function goBack() { prompt = null; }
        function submit(values) { prompt = null; }
        function chooseFilter(id, keepFocus) { activeFilter = id; if (!keepFocus) focusSearch(); }
        function cycleDeviceTab(delta, keepFocus) {
            if (modeId !== "devices" || prompt || pickingMode) return;
            const index = filters.findIndex(tab => tab.id === activeFilter);
            chooseFilter(filters[(index + delta + filters.length) % filters.length].id, keepFocus);
        }
        function retry() {}
    }
    Launcher { id: preview; state: fixture }
    Timer {
        interval: 600
        running: true
        repeat: true
        onTriggered: {
            const names = ["compact", "expanded", "prompt", "devices"];
            if (test.step < 4) {
                const name = names[test.step];
                preview.surface.grabToImage(result => { result.saveToFile("/tmp/boron-" + name + ".png"); test.advance(); });
            }
        }
    }
    function advance() {
            test.step++;
            if (test.step === 1) {
                fixture.query = "fi";
                fixture.rows = [
                    {id: "firefox", title: "Firefox", subtitle: "Web browser", icon: Quickshell.iconPath("firefox", true)},
                    {id: "files", title: "Files", subtitle: "Browse your files", icon: Quickshell.iconPath("org.gnome.Nautilus", true)},
                    {id: "filezilla", title: "FileZilla", subtitle: "FTP and SFTP client"},
                    {id: "fish", title: "Fish", subtitle: "Interactive shell · Opens in Kitty"}
                ];
            } else if (test.step === 2) {
                fixture.modeId = "github"; fixture.mode = {label: "GitHub"};
                fixture.prompt = {title: "Confirm pull request merge", description: "boron/launcher #12 → main\nImprove keyboard navigation\nHead: abc123 · Checks: 4/4 · Review: APPROVED\nRepository rules apply. The branch is preserved.",
                    submitLabel: "Merge / queue PR", destructive: true,
                    fields: [{id: "method", label: "Merge method", type: "select", options: ["squash", "merge"], value: "squash"}]};
            } else if (test.step === 3) {
                fixture.prompt = null; fixture.query = ""; fixture.modeId = "devices"; fixture.mode = {label: "Devices"};
                fixture.filters = [{id: "wifi", label: "Wi-Fi"}, {id: "bluetooth", label: "Bluetooth"}];
                fixture.activeFilter = "wifi";
                fixture.selectedIndex = 2;
                fixture.rows = [{id: "power", title: "Turn Wi-Fi off", subtitle: "Wireless radio"}, {id: "adapter", title: "wlan0", subtitle: "Selected adapter"}, {id: "home", title: "Home network", subtitle: "Connected · WPA2 · 95%"}, {id: "guest", title: "Guest network", subtitle: "Disconnected · WPA2 · 72%"}];
            } else if (test.step === 4) {
                console.log("VISUAL SMOKE PASSED");
                Qt.quit();
            }
    }
}
