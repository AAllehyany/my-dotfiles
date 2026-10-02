// Actual key events against the production view/controller, with inert result rows.
import QtQuick
import Quickshell
import QtTest 1.2
import "features/launcher"

ShellRoot {
    id: test
    property int step: 0
    property string previousTab: ""
    property int activations: 0
    QtObject {
        id: fixtureNetwork
        readonly property bool connected: true
        function disconnect() { test.activations++; }
    }
    LauncherState { id: state } // closed: no device scans or remote queries
    Window {
        id: host
        visible: true; width: 1000; height: 800
        LauncherView {
            id: view
            anchors.fill: parent
            state: state
            visible: true
            TestEvent { id: keys }
        }
    }
    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = find(child, name);
            if (found) return found;
        }
        return null;
    }
    function check(condition, message) {
        if (!condition) { steps.stop(); throw new Error("NAVIGATION SMOKE FAILED at " + step + ": " + message); }
    }
    function press(key, modifiers) { check(keys.keyClick(key, modifiers || Qt.NoModifier, 0), "key delivered"); }
    function tabFocused(id) { return find(view, "deviceTab-" + id).activeFocus; }
    Timer {
        id: steps
        interval: 100; running: true; repeat: true
        onTriggered: {
            const search = find(view, "launcherSearch");
            const results = find(view, "launcherResults");
            switch (test.step++) {
            case 0:
                state.switchMode("devices", "wifi");
                state.adapter.results = Array.from({length: 20}, (_, i) => ({id: "fixture:" + i, title: "Device " + i, subtitle: "Fixture only", network: fixtureNetwork}));
                break;
            case 1: check(search.activeFocus, "search initially focused"); press(Qt.Key_Tab); break;
            case 2: check(tabFocused("wifi"), "Tab enters selected tab; focus=" + host.activeFocusItem); press(Qt.Key_Right); break;
            case 3: check(state.activeFilter === "bluetooth" && tabFocused("bluetooth"), "Right switches tab and retains tab focus"); press(Qt.Key_Right); break;
            case 4: check(state.activeFilter === "wifi" && tabFocused("wifi"), "Right wraps"); press(Qt.Key_Left); break;
            case 5: check(state.activeFilter === "bluetooth" && tabFocused("bluetooth"), "Left wraps"); press(Qt.Key_Home); break;
            case 6: check(state.activeFilter === "wifi" && tabFocused("wifi"), "Home selects first tab"); press(Qt.Key_End); break;
            case 7: check(state.activeFilter === "bluetooth" && tabFocused("bluetooth"), "End selects last tab"); press(Qt.Key_Tab); break;
            case 8: check(results.activeFocus, "Tab enters results"); press(Qt.Key_Up); break;
            case 9: check(tabFocused("bluetooth"), "Up from first result returns to tabs"); press(Qt.Key_Down); break;
            case 10: check(results.activeFocus, "Down enters results"); press(Qt.Key_Down); break;
            case 11: check(state.selectedIndex === 1, "Down moves result selection"); press(Qt.Key_Tab, Qt.ControlModifier); break;
            case 12: check(state.activeFilter === "wifi" && results.activeFocus && state.modeId === "devices", "Ctrl+Tab switches tabs while keeping results focused"); press(Qt.Key_Backtab, Qt.ControlModifier | Qt.ShiftModifier); break;
            case 13: check(state.activeFilter === "bluetooth" && results.activeFocus, "Ctrl+Shift+Tab switches backward"); press(Qt.Key_Backtab, Qt.ShiftModifier); break;
            case 14: check(tabFocused("bluetooth"), "Shift+Tab returns to selected tab"); press(Qt.Key_Backtab, Qt.ShiftModifier); break;
            case 15: check(search.activeFocus, "Shift+Tab returns to search"); keys.keyClickChar("h", Qt.NoModifier, 0); break;
            case 16: check(state.query === "h", "typing edits search"); press(Qt.Key_Left); break;
            case 17: check(state.activeFilter === "bluetooth" && search.activeFocus, "search arrows edit text without changing tabs"); press(Qt.Key_Tab, Qt.ControlModifier); break;
            case 18: check(state.activeFilter === "wifi" && search.activeFocus && state.query === "", "tab shortcut from search retains search focus"); press(Qt.Key_Tab); break;
            case 19: check(tabFocused("wifi"), "tabs regain focus"); press(Qt.Key_Return); break;
            case 20: check(results.activeFocus && !state.prompt, "Enter enters results without activating a device"); press(Qt.Key_Tab); break;
            case 21: check(find(view, "launcherModeButton").activeFocus, "Tab from results reaches mode button"); press(Qt.Key_Tab); break;
            case 22: check(search.activeFocus, "focus loop returns to search"); press(Qt.Key_Backtab, Qt.ShiftModifier); break;
            case 23: check(find(view, "launcherModeButton").activeFocus, "reverse focus loop reaches mode button"); press(Qt.Key_Backtab, Qt.ShiftModifier); break;
            case 24: check(results.activeFocus, "reverse focus loop reaches results"); press(Qt.Key_Backtab, Qt.ShiftModifier); break;
            case 25: check(tabFocused("wifi"), "reverse focus loop reaches tab"); keys.keyClickChar("t", Qt.NoModifier, 0); break;
            case 26: check(search.activeFocus && state.query === "t", "typing on tabs resumes search"); press(Qt.Key_PageDown, Qt.ControlModifier); break;
            case 27: check(state.modeId !== "devices", "Ctrl+PageDown changes launcher mode"); press(Qt.Key_PageUp, Qt.ControlModifier); break;
            case 28:
                check(state.modeId === "devices", "Ctrl+PageUp returns to Devices");
                test.previousTab = state.activeFilter;
                state.prompt = {title: "Fixture password", fields: [{id: "password", type: "password", label: "Password"}]};
                break;
            case 29: press(Qt.Key_Tab, Qt.ControlModifier); break;
            case 30: check(state.activeFilter === test.previousTab && state.prompt, "shortcuts do not leave a prompt"); state.goBack(); break;
            case 31: check(search.activeFocus, "cancel prompt restores search focus"); press(Qt.Key_Right, Qt.AltModifier); break;
            case 32: check(state.activeFilter !== test.previousTab && search.activeFocus, "Alt+Right compatibility shortcut"); state.showModes(); break;
            case 33: test.previousTab = state.activeFilter; press(Qt.Key_Right, Qt.AltModifier); break;
            case 34: check(state.activeFilter === test.previousTab && state.pickingMode, "device shortcuts inactive in mode picker"); state.goBack(); break;
            case 35: view.visible = false; test.previousTab = state.activeFilter; press(Qt.Key_Tab, Qt.ControlModifier); break;
            case 36:
                check(state.activeFilter === test.previousTab, "hidden launcher shortcuts inactive");
                view.visible = true;
                break;
            case 37: press(Qt.Key_Tab); break;
            case 38:
                check(tabFocused(state.activeFilter), "tab focused after reopening");
                state.adapter.results = state.adapter.results.map(row => Object.assign({}, row, {subtitle: "Refreshed"}));
                break;
            case 39: check(tabFocused(state.activeFilter), "refresh preserves tab focus"); press(Qt.Key_Space); break;
            case 40: check(results.activeFocus && test.activations === 0, "Space enters results without activating a device"); press(Qt.Key_Return); break;
            case 41: check(test.activations === 1, "Enter activates the selected fixture result"); press(Qt.Key_End); break;
            case 42: check(state.selectedIndex === state.rows.length - 1, "End selects last result"); press(Qt.Key_Home); break;
            case 43: check(state.selectedIndex === 0, "Home selects first result"); press(Qt.Key_PageDown); break;
            case 44:
                check(state.selectedIndex > 0, "PageDown advances results");
                test.previousTab = state.activeFilter;
                const target = find(view, "deviceTab-" + (state.activeFilter === "wifi" ? "bluetooth" : "wifi"));
                check(keys.mouseClick(target, target.width / 2, target.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "mouse click delivered");
                break;
            case 45:
                check(state.activeFilter !== test.previousTab && tabFocused(state.activeFilter), "mouse selection and keyboard focus stay in sync");
                state.adapter.results = [];
                break;
            case 46: press(Qt.Key_Down); break;
            case 47:
                check(search.activeFocus, "empty device results return focus to search");
                state.switchMode("apps", "");
                break;
            case 48: keys.keyClickChar("@", Qt.NoModifier, 0); break;
            case 49:
                check(state.completingMode && state.rows.some(row => row.title === "@wifi"), "typing @ displays completion suggestions");
                keys.keyClickChar("w", Qt.NoModifier, 0); keys.keyClickChar("i", Qt.NoModifier, 0);
                break;
            case 50: check(state.rows.length === 1 && state.rows[0].title === "@wifi", "partial prefix narrows suggestions"); press(Qt.Key_Tab); break;
            case 51:
                check(state.modeId === "devices" && state.activeFilter === "wifi" && search.activeFocus && state.query === "", "Tab accepts completion and retains search focus");
                for (const c of "@blu") keys.keyClickChar(c, Qt.NoModifier, 0);
                break;
            case 52: check(state.rows[0].title === "@bluetooth", "Bluetooth completion available within Devices"); press(Qt.Key_Return); break;
            case 53:
                check(state.activeFilter === "bluetooth" && search.activeFocus && test.activations === 1, "Enter accepts completion without activating a device");
                for (const c of "@no-such-mode") keys.keyClickChar(c, Qt.NoModifier, 0);
                break;
            case 54: check(state.completingMode && state.rows.length === 0, "unknown prefix has no suggestions"); press(Qt.Key_Tab); break;
            case 55: check(search.activeFocus && state.activeFilter === "bluetooth", "Tab with no match stays in search"); press(Qt.Key_Escape); break;
            case 56:
                check(!state.completingMode && state.query === "" && view.visible, "Escape clears completion without closing launcher");
                keys.keyClickChar("@", Qt.NoModifier, 0); press(Qt.Key_Down);
                break;
            case 57:
                check(state.selectedIndex === 1, "arrow keys navigate completion suggestions");
                press(Qt.Key_Up); press(Qt.Key_Return);
                break;
            case 58:
                check(state.modeId === "apps" && search.activeFocus, "selected suggestion routes to its mode; mode=" + state.modeId + ", focus=" + host.activeFocusItem + ", query=" + state.query);
                console.warn("NAVIGATION SMOKE PASSED"); Qt.quit();
            }
        }
    }
}
