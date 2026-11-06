// Actual key events against the production view/controller, with inert result rows.
import QtQuick
import Quickshell
import QtTest 1.2
import "features/launcher"
import "tests"

ShellRoot {
    id: test
    property int step: 0
    property string previousTab: ""
    property int activations: 0
    property int forgets: 0
    property int baseline: 0
    QtObject {
        id: fixtureNetwork
        readonly property bool connected: true
        function disconnect() { test.activations++; }
        function forget() { test.forgets++; }
    }
    function deviceRows() {
        return Array.from({length: 20}, (_, i) => ({id: "fixture:" + i, title: "Device " + i, subtitle: "Fixture only", network: fixtureNetwork,
            actions: [{id: "connect", title: "Disconnect"}, {id: "forget", title: "Forget fixture"}]}));
    }
    LauncherState { id: state; historyPath: "" } // closed: no device scans or remote queries
    FixtureTray { id: fixtureTray }
    FixtureTray { id: secondTray; title: "Second" }
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
    function tabFocused(id) { return find(view, "filterTab-" + id).activeFocus; }
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
                const target = find(view, "filterTab-" + (state.activeFilter === "wifi" ? "bluetooth" : "wifi"));
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
                press(Qt.Key_Q, Qt.ControlModifier);
                break;
            case 59:
                check(!state.prompt && !fixtureTray.quitCount, "Ctrl+Q is inactive outside Tray");
                state.switchMode("tray", "");
                state.adapter.items = [fixtureTray, secondTray];
                state.adapter.quitLookup.openerComponent = fixtureTray.openerComponent;
                state.selectResult(1);
                break;
            case 60: press(Qt.Key_Q, Qt.ControlModifier); break;
            case 61:
                check(state.prompt && state.prompt.title === "Quit Second?" && secondTray.quitCount === 0, "Ctrl+Q targets selected tray app and requires confirmation");
                check(host.activeFocusItem.text === "Cancel", "quit prompt initially focuses Cancel");
                press(Qt.Key_Q, Qt.ControlModifier);
                press(Qt.Key_Space);
                break;
            case 62:
                check(!state.prompt && secondTray.quitCount === 0 && search.activeFocus, "Space on initial Cancel leaves app running and restores focus");
                state.showActions();
                break;
            case 63: press(Qt.Key_Q, Qt.ControlModifier); break;
            case 64:
                check(state.prompt && state.prompt.title === "Quit Second?", "Ctrl+Q in additional actions targets their owning app");
                press(Qt.Key_Tab);
                break;
            case 65:
                check(host.activeFocusItem.text === "Quit", "Quit is keyboard reachable");
                press(Qt.Key_Space);
                break;
            case 66:
                check(secondTray.quitCount === 1 && fixtureTray.quitCount === 0 && !state.prompt && !state.opened, "confirmed Quit invokes exactly the selected app command");
                state.switchMode("tray", "");
                state.showModes();
                press(Qt.Key_Q, Qt.ControlModifier);
                break;
            case 67:
                check(state.pickingMode && !state.prompt, "Ctrl+Q inactive in mode picker");
                state.goBack(); state.setQuery("@");
                press(Qt.Key_Q, Qt.ControlModifier);
                break;
            case 68:
                check(state.completingMode && !state.prompt, "Ctrl+Q inactive in mode completion");
                state.goBack();
                state.selectResult(state.rows.findIndex(row => row.id === "restart"));
                press(Qt.Key_Q, Qt.ControlModifier);
                break;
            case 69:
                check(!state.prompt && !state.loading, "Ctrl+Q does not invoke power rows");
                state.selectResult(0); view.visible = false;
                press(Qt.Key_Q, Qt.ControlModifier);
                break;
            case 70:
                check(!state.prompt && secondTray.quitCount === 1, "hidden launcher ignores Ctrl+Q");
                view.visible = true;
                state.adapter.menuStack = [null];
                press(Qt.Key_Q, Qt.ControlModifier);
                break;
            case 71:
                check(!state.prompt, "Ctrl+Q inactive inside tray menus");
                state.adapter.cancel();
                fixtureTray.menu.entries = [];
                press(Qt.Key_Q, Qt.ControlModifier);
                break;
            case 72:
                check(state.loading && !state.prompt, "Ctrl+Q waits for an unloaded tray menu");
                press(Qt.Key_Q, Qt.ControlModifier);
                press(Qt.Key_Escape);
                break;
            case 73:
                check(!state.loading && !state.prompt && !state.adapter.quitLookup.openers.length, "Escape cancels pending lookup and repeated Ctrl+Q cannot duplicate it");
                state.switchMode("devices", "wifi");
                state.adapter.results = test.deviceRows();
                break;
            case 74:
                check(search.activeFocus, "search focused for keyboard extensions");
                state.selectResult(5);
                keys.keyClickChar("d", Qt.NoModifier, 0);
                break;
            case 75:
                check(state.query === "d" && state.selectedIndex === 0, "typing selects the first result; index=" + state.selectedIndex);
                press(Qt.Key_Backspace);
                break;
            case 76:
                check(state.query === "" && state.modeId === "devices", "Backspace with text edits the query only");
                test.baseline = test.activations;
                press(Qt.Key_3, Qt.AltModifier);
                break;
            case 77:
                check(test.activations === test.baseline + 1 && state.selectedIndex === 0, "Alt+3 runs the third visible row");
                press(Qt.Key_J, Qt.AltModifier); press(Qt.Key_J, Qt.AltModifier); press(Qt.Key_K, Qt.AltModifier);
                break;
            case 78:
                check(state.selectedIndex === 1, "Alt+J / Alt+K move the selection");
                check(state.secondaryAction && state.secondaryAction.id === "forget", "secondary action is the second action");
                press(Qt.Key_Return, Qt.ShiftModifier);
                break;
            case 79:
                check(state.prompt && state.prompt.title === "Forget Device 1?", "Shift+Enter runs the secondary action");
                check(host.activeFocusItem.objectName === "promptCancel", "destructive prompt focuses Cancel");
                press(Qt.Key_Return);
                break;
            case 80:
                check(!state.prompt && test.forgets === 0 && search.activeFocus, "Enter on a focused Cancel button cancels");
                press(Qt.Key_Return, Qt.ShiftModifier);
                break;
            case 81: press(Qt.Key_Right); break;
            case 82: check(host.activeFocusItem.objectName === "promptConfirm", "Right moves to Confirm"); press(Qt.Key_Left); break;
            case 83: check(host.activeFocusItem.objectName === "promptCancel", "Left moves back to Cancel"); press(Qt.Key_Return, Qt.ControlModifier); break;
            case 84:
                check(!state.prompt && test.forgets === 1, "Ctrl+Enter submits the prompt");
                state.adapter.results = test.deviceRows();
                press(Qt.Key_PageDown);
                break;
            case 85: check(state.selectedIndex > 1, "PageDown pages from search"); press(Qt.Key_End); break;
            case 86: check(state.selectedIndex === state.rows.length - 1, "End on empty search selects last"); press(Qt.Key_Home); break;
            case 87:
                check(state.selectedIndex === 0, "Home on empty search selects first");
                state.switchMode("tray", "");
                state.adapter.items = [fixtureTray, secondTray];
                break;
            case 88: press(Qt.Key_Tab); break;
            case 89: check(results.activeFocus, "Tab enters results outside Devices"); press(Qt.Key_Down); break;
            case 90: check(state.selectedIndex === 1 && results.activeFocus, "arrows navigate results outside Devices"); press(Qt.Key_Tab); break;
            case 91: check(find(view, "launcherModeButton").activeFocus, "Tab from results reaches mode button"); press(Qt.Key_Tab); break;
            case 92:
                check(search.activeFocus, "focus loop returns to search outside Devices");
                state.adapter.menuStack = [null];
                press(Qt.Key_Left);
                break;
            case 93: check(state.modeId === "tray" && !state.adapter.menuStack.length, "Left on empty search leaves a tray menu"); press(Qt.Key_Backspace); break;
            case 94: check(state.modeId === "apps" && search.activeFocus, "Backspace on empty search returns to Applications"); press(Qt.Key_3, Qt.ControlModifier); break;
            case 95: check(state.modeId === "devices", "Ctrl+3 switches to the third mode"); press(Qt.Key_1, Qt.ControlModifier); break;
            case 96: check(state.modeId === "apps", "Ctrl+1 switches to Applications"); press(Qt.Key_M, Qt.ControlModifier); break;
            case 97:
                check(state.pickingMode && state.rows[2].id === "devices" && state.rows[2].subtitle.indexOf("Ctrl+3") >= 0, "picker lists modes in order with Ctrl+N hints");
                press(Qt.Key_Backspace);
                break;
            case 98: check(!state.pickingMode && state.modeId === "apps", "Backspace on empty search leaves the picker"); press(Qt.Key_Slash, Qt.ControlModifier); break;
            case 99:
                check(state.helpMode && state.rows.length > 5 && state.rows.some(r => r.title === "Alt+1–9"), "Ctrl+/ shows keyboard help");
                for (const c of "close") keys.keyClickChar(c, Qt.NoModifier, 0);
                break;
            case 100:
                check(state.helpMode && state.rows.length && state.rows[0].title.indexOf("Ctrl+W") >= 0, "help is searchable; first=" + (state.rows[0] || {}).title);
                press(Qt.Key_Return);
                break;
            case 101: check(state.helpMode, "help rows are inert"); press(Qt.Key_Escape); break;
            case 102: check(!state.helpMode, "Escape closes help"); press(Qt.Key_F1); break;
            case 103:
                check(state.helpMode, "F1 opens help");
                press(Qt.Key_F1);
                state.switchMode("fixture-plugin", "");
                state.adapter.filters = [{id: "a", label: "A"}, {id: "b", label: "B"}];
                break;
            case 104: check(!state.helpMode && state.filters.length === 2, "plugin filters visible"); press(Qt.Key_Tab, Qt.ControlModifier); break;
            case 105: check(state.activeFilter === "b" && state.modeId === "fixture-plugin", "Ctrl+Tab cycles plugin filters"); press(Qt.Key_Tab); break;
            case 106:
                check(tabFocused("b"), "Tab reaches plugin filter tabs");
                state.switchMode("apps", "");
                state.prompt = {title: "Fixture prompt", fields: []};
                break;
            case 107: press(Qt.Key_W, Qt.ControlModifier); break;
            case 108:
                check(!state.prompt && !state.opened, "Ctrl+W closes from inside a prompt");
                console.warn("NAVIGATION SMOKE PASSED"); Qt.quit();
            }
        }
    }
}
