import QtQuick
import Quickshell

// Keep every opened menu alive until the caller confirms or cancels.
QtObject {
    id: root
    property Component openerComponent: Component { QsMenuOpener {} }
    property var menuRoot: null
    property string appTitle: ""
    property var openers: []
    property bool running: false
    signal found(var entry)
    signal unavailable()

    property Timer poll: Timer {
        interval: 50
        repeat: true
        onTriggered: root.scan()
    }
    property Timer deadline: Timer {
        interval: 2000
        onTriggered: {
            root.scan();
            if (!root.running) return;
            root.cancel();
            root.unavailable();
        }
    }

    function normalized(text) {
        return String(text || "").replace(/&/g, "").replace(/(?:\.{3}|…)\s*$/, "").trim().toLowerCase();
    }
    function matches(entry) {
        const label = normalized(entry.text);
        const name = normalized(appTitle);
        return label === "quit" || label === "exit"
            || (name && (label === "quit " + name || label === "exit " + name));
    }
    function openedMenu(handle) {
        const existing = openers.find(item => item.handle === handle);
        if (existing) return existing.opener;
        const opened = openerComponent.createObject(root, {menu: handle});
        if (opened) openers.push({handle: handle, opener: opened});
        return opened;
    }
    function candidates() {
        const commands = [];
        const queue = menuRoot ? [menuRoot] : [];
        const visited = new Set();
        // Breadth first: root commands precede submenu commands.
        for (let i = 0; i < queue.length; i++) {
            const handle = queue[i];
            if (!handle || visited.has(handle)) continue;
            visited.add(handle);
            const opened = openedMenu(handle);
            const children = opened && opened.children ? opened.children.values : [];
            for (const entry of children) {
                if (!entry || entry.isSeparator || !entry.enabled) continue;
                if (entry.hasChildren) queue.push(entry);
                else if (matches(entry)) commands.push(entry);
            }
        }
        return commands;
    }
    function scan() {
        if (!running) return;
        const commands = candidates();
        if (!commands.length) return;
        running = false;
        poll.stop();
        deadline.stop();
        found(commands[0]);
    }
    function start(menu, title) {
        cancel();
        menuRoot = menu;
        appTitle = title;
        running = true;
        deadline.start();
        poll.start();
        scan();
    }
    function isAvailable(entry) { return !!entry && candidates().indexOf(entry) !== -1; }
    function cancel() {
        running = false;
        poll.stop();
        deadline.stop();
        menuRoot = null;
        for (const item of openers) {
            item.opener.menu = null;
            item.opener.destroy();
        }
        openers = [];
    }
}
