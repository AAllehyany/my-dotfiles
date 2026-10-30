import QtQuick
import Quickshell
import "features/launcher"
import "tests"

ShellRoot {
    id: test
    property int step: 0
    property int waited: 0
    property var disposable: null
    LauncherState { id: state } // closed: no desktop scans or remote queries
    FixtureTray { id: app }
    FixtureTray { id: otherApp; title: "Other" }
    QtObject {
        id: submenu
        property string text: "Application"
        property bool enabled: true
        property bool isSeparator: false
        property bool hasChildren: true
        property var entries: []
    }
    QtObject {
        id: unrelated
        property string text: "Close window"
        property bool enabled: true
        property bool isSeparator: false
        property bool hasChildren: false
        signal triggered()
        onTriggered: { throw new Error("Unrelated menu action triggered"); }
    }
    Component { id: trayFactory; FixtureTray {} }
    function check(condition, message) {
        if (!condition) { steps.stop(); throw new Error("TRAY QUIT SMOKE FAILED at " + step + ": " + message); }
    }
    function begin(entries) {
        state.goBack();
        state.switchMode("tray", "");
        state.adapter.items = [app, otherApp];
        state.adapter.quitLookup.openerComponent = app.openerComponent;
        app.menu.entries = entries;
        app.quitEntry.enabled = true;
        state.selectedIndex = 0;
        state.selectedId = state.rows[0].id;
        state.quitTray();
    }
    Timer {
        id: steps
        interval: 100; running: true; repeat: true
        onTriggered: {
            switch (test.step++) {
            case 0:
                begin([app.quitEntry]);
                check(state.prompt && state.prompt.title === "Quit Fixture?" && app.quitCount === 0, "confirmation precedes quit");
                state.goBack();
                check(!state.prompt && !state.adapter.quitLookup.openers.length, "cancel clears the lookup");
                break;
            case 1:
                check(app.liveOpeners === 0 && app.quitCount === 0, "cancel releases menu handles without quitting");
                begin([app.quitEntry]);
                state.submit({});
                check(app.quitCount === 1 && !state.prompt && !state.opened, "confirmation invokes once and closes");
                state.submit({});
                check(app.quitCount === 1, "repeat submit cannot invoke again");
                break;
            case 2:
                submenu.entries = [otherApp.quitEntry];
                begin([submenu, app.quitEntry]);
                check(state.adapter.quitCommand === app.quitEntry, "root command wins over an earlier submenu");
                state.goBack();
                app.quitEntry.text = "E&XIT Fixture...";
                submenu.entries = [app.quitEntry];
                begin([unrelated, submenu]);
                check(state.prompt && state.adapter.quitCommand === app.quitEntry, "nested Exit with app name and mnemonic matches");
                state.submit({});
                check(app.quitCount === 2 && otherApp.quitCount === 0, "only selected nested command invokes");
                break;
            case 3:
                begin([]);
                check(state.loading && !state.prompt, "empty menu waits for asynchronous population");
                app.menu.entries = [submenu];
                submenu.entries = [];
                break;
            case 4:
                check(state.loading && !state.prompt, "nested menus also load asynchronously");
                submenu.entries = [app.quitEntry];
                break;
            case 5:
                check(state.prompt && !state.loading, "delayed nested command opens confirmation");
                app.quitEntry.enabled = false;
                state.submit({});
                check(app.quitCount === 2 && state.message.includes("no longer available"), "disabled command is rejected at confirmation");
                break;
            case 6:
                begin([app.quitEntry]);
                app.menu.entries = [];
                state.submit({});
                check(app.quitCount === 2 && state.message.includes("no longer available"), "removed command cannot invoke");
                begin([submenu]);
                submenu.enabled = false;
                state.submit({});
                check(app.quitCount === 2, "disabled submenu invalidates its command");
                submenu.enabled = true;
                break;
            case 7:
                begin([]);
                state.setQuery("Fixture");
                app.menu.entries = [app.quitEntry];
                break;
            case 8:
                check(!state.prompt && !state.loading && !state.adapter.quitLookup.openers.length, "query change cancels pending lookup");
                begin([]);
                state.selectResult(1);
                app.menu.entries = [app.quitEntry];
                break;
            case 9:
                check(!state.prompt && !state.loading, "selection change cancels pending lookup");
                begin([]);
                state.switchMode("apps", "");
                app.menu.entries = [app.quitEntry];
                break;
            case 10:
                check(!state.prompt && app.liveOpeners === 0, "leaving Tray releases pending menus");
                begin([app.quitEntry]);
                state.adapter.items = [otherApp];
                state.submit({});
                check(app.quitCount === 2 && state.message.includes("no longer available"), "withdrawn app cannot quit");
                begin([]);
                state.adapter.items = [];
                check(!state.loading && state.message.includes("no longer available"), "withdrawal cancels pending lookup");
                break;
            case 11:
                begin([]);
                state.activate();
                check(app.openCount === 1 && !state.loading && !state.adapter.quitLookup.openers.length, "another action cancels pending quit lookup");
                begin([app.quitEntry]);
                state.goBack();
                disposable = trayFactory.createObject(test, {title: "Disposable"});
                state.adapter.items = [disposable];
                state.quitTray();
                check(!!state.prompt, "disposable app confirmation opened");
                state.adapter.items = [];
                disposable.destroy();
                break;
            case 12:
                state.submit({});
                check(!state.prompt && state.message.includes("no longer available"), "destroyed app is rejected safely");
                begin([unrelated, app.quitEntry]);
                state.goBack();
                app.quitEntry.enabled = false;
                state.quitTray();
                test.waited = 0;
                break;
            case 13:
                if (state.loading && test.waited++ < 25) { test.step--; break; }
                check(!state.loading && !state.prompt && state.message.includes("No supported"), "disabled/unrelated commands time out with a notice");
                check(app.quitCount === 2 && app.liveOpeners === 0, "timeout releases handles and performs no actions");
                app.quitEntry.text = "Quit Other";
                app.quitEntry.enabled = true;
                check(!state.adapter.quitLookup.matches(app.quitEntry), "another app's Quit command does not match");
                app.quitEntry.text = "Quit";
                begin([app.quitEntry]);
                app.quitEntry.destroy();
                break;
            case 14:
                state.submit({});
                check(app.quitCount === 2 && state.message.includes("no longer available"), "destroyed menu command is rejected safely");
                app.menu = null;
                state.quitTray();
                check(!state.loading && !state.prompt && state.message.includes("No supported"), "app without menu reports immediately");
                console.warn("TRAY QUIT SMOKE PASSED");
                Qt.quit();
            }
        }
    }
}
