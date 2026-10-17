// Fixture-only UI and lifecycle checks. Never starts a desktop notification server.
import QtQuick
import QtTest 1.2
import Quickshell
import "features/notifications"
import "features/launcher"
import "tests"

ShellRoot {
    id: test
    property int step: 0
    property int nextId: 0
    property int invoked: 0
    property var timed: null
    property var transientNotice: null
    property var older: null
    property double startedAt: 0
    property double updateAt: 0
    property double hiddenAfter: 0
    NotificationService {
        id: service
        screens: [{name: "left", width: 1920, height: 1080}, {name: "right", width: 1280, height: 720}]
        centerVisible: state.notificationCenterVisible
    }
    LauncherState { id: state; notificationService: service }
    Component { id: fixture; FixtureNotification {} }
    QtObject {
        id: defaultAction
        property string identifier: "default"
        property string text: "Open"
        function invoke() { test.invoked++; }
    }
    QtObject {
        id: extraAction
        property string identifier: "reply"
        property string text: "Reply"
        function invoke() { test.invoked += 10; }
    }
    Window {
        id: host
        visible: true; width: 1000; height: 800
        LauncherView { id: view; anchors.fill: parent; state: state; TestEvent { id: events } }
    }
    function check(condition, message) {
        if (!condition) { steps.stop(); console.error("NOTIFICATIONS SMOKE FAILED at " + step + ": " + message); Qt.exit(1); }
    }
    function make(values, output) {
        const notification = fixture.createObject(test, Object.assign({id: ++nextId}, values || {}));
        service.receive(notification, output || "left");
        return notification;
    }
    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = find(child, name);
            if (found) return found;
        }
        return null;
    }
    Timer {
        id: steps
        interval: 80; running: true; repeat: true
        onTriggered: {
            const list = find(view, "launcherResults");
            switch (test.step++) {
            case 0: {
                older = make({summary: "Oldest"});
                make({summary: "Second"}); make({summary: "Third"}); make({summary: "Newest"});
                check(service.history.length === 4 && service.toasts.length === 3, "overflow stays in history");
                check(!service.find(older.id).toastVisible && service.toasts[0].title === "Newest", "newest at bottom, oldest evicted");
                make({summary: "Other output"}, "right");
                check(service.toasts.length === 4, "independent output stacks");
                service.screens = [{name: "left", width: 1920, height: 1080}];
                check(service.toasts.length === 3 && service.toasts.every(entry => entry.screenName === "left"), "unplug migrates and trims stack");
                service.markVisibleRead([String(older.id)]);
                check(!service.find(older.id).unread && service.unreadCount === 4, "read state is per entry");
                older.summary = "Updated oldest";
                break;
            }
            case 1:
                check(service.find(older.id).unread && !service.find(older.id).toastVisible && service.history.length === 5, "replacement becomes unread without replay or duplicate");
                service.clear();
                check(!service.entries.length && older.dismissed, "clear dismisses native entries");
                timed = make({summary: "Deadline", actions: [defaultAction], urgency: 2});
                transientNotice = make({hints: {transient: true}});
                startedAt = Date.now();
                const record = service.find(timed.id);
                record.toastVisibleChanged.connect(() => { if (!record.toastVisible) test.hiddenAfter = Date.now() - test.startedAt; });
                check(service.history.length === 1 && service.toasts.length === 2, "transient has toast but no history");
                break;
            case 2:
                timed.body = "Updated without extending the deadline";
                updateAt = Date.now();
                break;
            case 3:
                if (Date.now() - startedAt < 3120) { test.step--; break; }
                check(!service.toasts.length && service.history.length === 1 && !timed.expired, "three-second timeout preserves live history, including critical");
                check(hiddenAfter <= 3050, "replacement does not extend original deadline: " + hiddenAfter);
                check(transientNotice.expired && !service.find(transientNotice.id), "transient expires completely");
                service.activate(timed.id, "default");
                check(invoked === 1 && timed.dismissed && !service.entries.length, "click invokes default and removes resident entry");
                const noDefault = make({actions: [extraAction]});
                service.activate(noDefault.id, "default");
                check(invoked === 1 && noDefault.dismissed, "never invokes an arbitrary non-default action");
                const closesOnInvoke = make({});
                closesOnInvoke.actions = [{identifier: "default", text: "Open", invoke: () => { test.invoked++; closesOnInvoke.dismiss(); }}];
                service.activate(closesOnInvoke.id, "default");
                check(invoked === 2 && !service.entries.length, "synchronous native close is safe");
                make({lastGeneration: true});
                check(!service.toasts.length && service.unreadCount === 0, "reload does not replay toasts or unread counts");
                service.clear();
                for (let i = 0; i < 14; i++) make({summary: "Message " + i, appName: "Inbox", body: "Searchable content " + i, actions: [extraAction]});
                state.switchMode("notifications", ""); state.opened = true;
                break;
            case 4:
                check(!service.toasts.length && state.rows[0].title === "Message 13", "opening center suppresses stack and retains newest-first order");
                check(service.unreadCount > 0 && service.unreadCount < 14, "only visible rows become read");
                const firstUnread = service.unreadCount;
                list.positionViewAtEnd();
                check(firstUnread > 0, "offscreen rows remain unread");
                break;
            case 5:
                check(!service.find(state.rows[state.rows.length - 1].id).unread, "scrolling marks newly visible rows read");
                state.setQuery("Inbox");
                check(state.rows.length === 14 && state.rows[0].title === "Message 13", "app search preserves chronology");
                state.setQuery("no-such-notification");
                check(!state.rows.length, "unmatched query");
                state.setQuery("");
                make({summary: "Arrived with center open"});
                check(!service.toasts.length && state.rows[0].title === "Arrived with center open", "new arrivals go directly into center");
                list.synchronize(); list.positionViewAtBeginning();
                break;
            case 6:
                check(!service.find(state.rows[0].id).unread, "visible arrival read after layout");
                state.setQuery("Message 5"); state.showActions();
                check(state.rows.some(row => row.id === "app:reply"), "native actions in Ctrl+K menu");
                state.activate(state.rows.findIndex(row => row.id === "app:reply"));
                check(invoked === 12 && !service.history.some(entry => entry.title === "Message 5"), "extra action invokes and removes");
                state.setQuery("Message 4");
                break;
            case 7: {
                const clear = find(view, "clearNotificationsButton");
                check(events.mouseClick(clear, clear.width / 2, clear.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "clear button click delivered");
                check(!service.entries.length && state.modeId === "notifications", "clear all ignores search and keeps center open");
                state.setQuery("@notifs ");
                check(state.modeId === "notifications" && !state.query, "alias routes to Notifications");
                state.switchMode("apps", "");
                const button = find(view, "notificationCenterButton");
                check(events.mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "header click delivered");
                check(state.modeId === "notifications", "header opens center");
                state.switchMode("apps", "");
                check(!service.toasts.length, "leaving center does not replay history");
                const withdrawn = make(); withdrawn.closed(3);
                check(!service.find(withdrawn.id) && !service.toasts.length, "sender withdrawal removes both views");
                const pendingTransient = fixture.createObject(test, {id: ++nextId, hints: {transient: true}});
                service.receive(pendingTransient);
                state.switchMode("notifications", "");
                check(pendingTransient.expired && !service.find(pendingTransient.id), "opening center cleans up a transient waiting for output resolution");
                console.warn("NOTIFICATIONS SMOKE PASSED"); Qt.quit();
            }
            }
        }
    }
    Timer { interval: 12000; running: true; onTriggered: { console.error("Notification smoke timed out"); Qt.exit(1); } }
}
