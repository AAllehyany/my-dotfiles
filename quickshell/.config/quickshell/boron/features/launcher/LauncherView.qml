import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../components"

import "../notifications"

Item {
    id: window
    required property var state
    readonly property Item surface: panel
    visible: state.opened
    // Tab/arrow focus model shared by every mode's result list.
    readonly property bool listNavigation: state.browsing && !state.actionRunning
    readonly property var notificationService: state.notificationService || null
    readonly property bool notificationList: state.modeId === "notifications" && state.browsing && !state.actionRow
    readonly property string footerHints: {
        const s = state;
        if (s.prompt) return "Tab Move   ↵ Choose   Ctrl+↵ Submit   Esc Cancel";
        if (s.helpMode) return "Type to filter   Esc / Ctrl+/ Close";
        if (s.completingMode) return "↑↓ Suggestions   Tab / ↵ Select mode   Esc Clear";
        if (s.pickingMode) return "↑↓ Navigate   ↵ Switch   Ctrl+1–9 Direct   Esc Back";
        if (s.actionRow) return "↑↓ Navigate   ↵ Run   Ctrl+K / Esc Back   Ctrl+/ Keys";
        const parts = ["↵ Open"];
        if (s.secondaryAction) {
            const title = s.secondaryAction.title;
            parts.push("⇧↵ " + (title.length > 24 ? title.slice(0, 23) + "…" : title));
        }
        parts.push("Ctrl+K Actions");
        if (s.canQuitTray && s.selectedRow && s.selectedRow.id.startsWith("tray:")) parts.push("Ctrl+Q Quit");
        if (s.canDismiss) parts.push("Ctrl+D " + (s.modeId === "apps" ? "Forget" : "Dismiss"));
        if (s.pluginError) parts.push("Ctrl+R Retry");
        parts.push("Ctrl+/ Keys");
        return parts.join("   ");
    }
    function markVisibleNotificationsRead() {
        if (!visible || !notificationList || !notificationService) return;
        const ids = [];
        for (let i = 0; i < list.count; i++) {
            const item = list.itemAtIndex(i);
            if (item && item.y + item.height > list.contentY && item.y < list.contentY + list.height) ids.push(item.rowData.id);
        }
        notificationService.markVisibleRead(ids);
    }
    Timer { id: readVisible; interval: 0; onTriggered: window.markVisibleNotificationsRead() }
    onNotificationListChanged: readVisible.restart()
    Connections {
        target: window.notificationService
        function onContentUpdated() { readVisible.restart(); }
    }
    onVisibleChanged: { if (visible) { Qt.callLater(() => search.forceActiveFocus()); readVisible.restart(); } }
    Component.onCompleted: { if (visible) Qt.callLater(() => search.forceActiveFocus()); }
    function focusResults() {
        if (!listNavigation || !state.rows.length) { search.forceActiveFocus(); return; }
        list.forceActiveFocus(Qt.TabFocusReason);
        list.revealSelection();
    }
    // Tab order: search → tabs → results → toolbar buttons → mode button.
    function focusStops() {
        return [
            {name: "search", available: true},
            {name: "tabs", available: tabs.visible && filterTabs.enabled},
            {name: "results", available: list.visible && state.rows.length > 0},
            {name: "clear", available: clearButton.visible && clearButton.enabled},
            {name: "retry", available: retryButton.visible},
            {name: "mode", available: modeButton.enabled}
        ];
    }
    function focusStop(name, reason) {
        if (name === "tabs") filterTabs.focusSelected(reason);
        else if (name === "results") { list.forceActiveFocus(reason); list.revealSelection(); }
        else ({search: search, clear: clearButton, retry: retryButton, mode: modeButton})[name].forceActiveFocus(reason);
    }
    function focusAdjacent(from, delta) {
        const stops = focusStops();
        const at = stops.findIndex(stop => stop.name === from);
        for (let step = 1; step <= stops.length; step++) {
            const stop = stops[((at + delta * step) % stops.length + stops.length) % stops.length];
            if (stop.available) { focusStop(stop.name, delta > 0 ? Qt.TabFocusReason : Qt.BacktabFocusReason); return; }
        }
    }
    function focusAbove() {
        if (tabs.visible && filterTabs.enabled) filterTabs.focusSelected();
        else search.forceActiveFocus(Qt.BacktabFocusReason);
    }
    function switchFilterTab(delta) {
        if (!listNavigation || !state.filters.length) return;
        const fromTabs = filterTabs.hasTabFocus();
        const fromResults = list.activeFocus;
        state.cycleFilter(delta, true);
        if (fromTabs) filterTabs.focusSelected();
        else if (fromResults) focusResults();
        else search.forceActiveFocus();
    }
    function pageResults(delta) {
        state.selectResult(state.selectedIndex + delta * Math.max(1, Math.floor(list.height / list.rowHeight)));
    }
    function activateVisible(position) {
        const index = list.topIndex + position;
        if (index < state.rows.length) state.activate(index);
    }
    function typeInSearch(text) {
        state.setQuery(state.query + text);
        search.forceActiveFocus();
        search.cursorPosition = search.text.length;
    }
    Connections {
        target: window.state
        function onFocusSearch() { Qt.callLater(() => search.forceActiveFocus()); }
        function onRevealSelection() { list.revealSelection(); }
    }
    MouseArea { anchors.fill: parent; onClicked: window.state.close() }
    Rectangle {
        id: panel
        readonly property real maxPanelHeight: Math.min(header.implicitHeight + Theme.searchHeight + Theme.rowHeight * 8 + Theme.footerHeight + 80, window.height - 48)
        width: Math.min(Theme.panelWidth, window.width - 48)
        height: Math.min(maxPanelHeight, column.implicitHeight + 2)
        x: Math.round((window.width - width) / 2)
        y: Math.max(24, Math.round((window.height - maxPanelHeight) / 2))
        color: Theme.background
        border.color: Theme.border
        clip: true
        Behavior on height { NumberAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: search.forceActiveFocus() }
        ColumnLayout {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            spacing: 0
            LauncherHeader {
                id: header
                Layout.fillWidth: true
                notificationService: window.notificationService
                notificationsEnabled: !window.state.prompt && !window.state.actionRunning
                onNotificationsRequested: window.state.openNotifications()
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.searchHeight
                color: Theme.surface
                RowLayout {
                    anchors { fill: parent; leftMargin: 18; rightMargin: 16 }
                    spacing: 14
                    Text { text: "⌕"; color: Theme.accent; font.pixelSize: 29 }
                    TextField {
                        id: search
                        objectName: "launcherSearch"
                        Layout.fillWidth: true
                        enabled: !window.state.prompt && !window.state.actionRunning
                        text: window.state.query
                        placeholderText: window.state.helpMode ? "Filter keyboard shortcuts…" : window.state.pickingMode ? "Switch mode…" : window.state.modeId === "apps" ? "Search applications…" : "Search " + window.state.mode.label.toLowerCase() + "…"
                        placeholderTextColor: Theme.muted
                        color: Theme.text
                        selectionColor: Theme.selection
                        selectedTextColor: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 17
                        selectByMouse: true
                        background: Item {}
                        onTextEdited: window.state.setQuery(text)
                        onAccepted: window.state.activate()
                        Keys.onPressed: event => {
                            const state = window.state;
                            const plain = event.modifiers === Qt.NoModifier;
                            const empty = text.length === 0;
                            switch (event.key) {
                            case Qt.Key_Up: if (!plain) return; state.move(-1); break;
                            case Qt.Key_Down: if (!plain) return; state.move(1); break;
                            case Qt.Key_PageUp: if (!plain) return; window.pageResults(-1); break;
                            case Qt.Key_PageDown: if (!plain) return; window.pageResults(1); break;
                            // With text, Home/End/Left/Right/Backspace keep editing the query.
                            case Qt.Key_Home: if (!plain || !empty) return; state.selectResult(0); break;
                            case Qt.Key_End: if (!plain || !empty) return; state.selectResult(state.rows.length - 1); break;
                            case Qt.Key_Backspace: if (!plain || !empty || !state.stepBack()) return; break;
                            case Qt.Key_Left: if (!plain || !empty || !state.menuBack()) return; break;
                            case Qt.Key_Right: if (!plain || !empty || !state.menuEnter()) return; break;
                            case Qt.Key_Return: case Qt.Key_Enter:
                                if (event.modifiers !== Qt.ShiftModifier) return;
                                state.activateSecondary(); break;
                            case Qt.Key_Tab:
                                if (state.completingMode) { state.activate(); break; }
                                if (!window.listNavigation) return;
                                window.focusAdjacent("search", 1); break;
                            case Qt.Key_Backtab:
                                if (state.completingMode) { state.move(-1); break; }
                                if (!window.listNavigation) return;
                                window.focusAdjacent("search", -1); break;
                            default: return;
                            }
                            event.accepted = true;
                        }
                    }
                    ActionButton {
                        id: modeButton
                        objectName: "launcherModeButton"
                        text: window.state.pickingMode ? "MODES" : window.state.helpMode ? "KEYS" : window.state.mode.label
                        enabled: !window.state.prompt && !window.state.actionRunning
                        onClicked: window.state.showModes()
                        Keys.onTabPressed: event => {
                            if (!window.listNavigation) { event.accepted = false; return; }
                            window.focusAdjacent("mode", 1);
                        }
                        Keys.onBacktabPressed: event => {
                            if (!window.listNavigation) { event.accepted = false; return; }
                            window.focusAdjacent("mode", -1);
                        }
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
            RowLayout {
                id: notificationToolbar
                visible: window.notificationList
                Layout.fillWidth: true
                Layout.leftMargin: 18; Layout.rightMargin: 16
                spacing: 12
                Text {
                    Layout.fillWidth: true
                    text: "NOTIFICATIONS"
                    color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.small
                }
                ActionButton {
                    id: clearButton
                    objectName: "clearNotificationsButton"
                    text: "Clear all"
                    enabled: !!window.notificationService && window.notificationService.history.length > 0
                    onClicked: window.notificationService.clear()
                    Keys.onTabPressed: window.focusAdjacent("clear", 1)
                    Keys.onBacktabPressed: window.focusAdjacent("clear", -1)
                }
            }
            Text {
                id: notificationError
                visible: window.notificationList && !!window.notificationService && !!window.notificationService.error
                Layout.fillWidth: true
                Layout.margins: visible ? 16 : 0
                text: window.notificationService ? window.notificationService.error : ""
                textFormat: Text.PlainText
                color: Theme.danger; font.family: Theme.font; font.pixelSize: Theme.small
                wrapMode: Text.Wrap
            }
            RowLayout {
                id: tabs
                visible: window.state.filters.length > 0 && window.state.browsing
                Layout.fillWidth: true
                Layout.margins: visible ? 8 : 0
                spacing: 6
                FilterTabs {
                    id: filterTabs
                    objectName: "filterTabs"
                    enabled: window.listNavigation
                    sections: tabs.visible ? window.state.filters : []
                    activeSection: window.state.activeFilter
                    onSectionRequested: section => window.state.chooseFilter(section, true)
                    onSearchRequested: search.forceActiveFocus(Qt.BacktabFocusReason)
                    onResultsRequested: window.focusResults()
                    onNextRequested: window.focusAdjacent("tabs", 1)
                    onTextEntered: text => window.typeInSearch(text)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Ctrl+Tab · Alt+←/→ Switch"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.small
                    Layout.rightMargin: 8
                }
            }
            Loader {
                id: promptLoader
                active: !!window.state.prompt
                visible: active
                Layout.fillWidth: true
                Layout.preferredHeight: active ? Math.min(item ? item.implicitHeight : 0, panel.maxPanelHeight - header.implicitHeight - Theme.searchHeight - Theme.footerHeight - 2) : 0
                sourceComponent: ScrollView {
                    clip: true
                    contentWidth: availableWidth
                    implicitHeight: promptContent.implicitHeight
                    PromptView {
                        id: promptContent
                        width: parent.width
                        prompt: window.state.prompt || {title: "", fields: []}
                        onSubmitted: values => window.state.submit(values)
                        onCanceled: window.state.goBack()
                    }
                }
            }
            ResultList {
                id: list
                objectName: "launcherResults"
                visible: !window.state.prompt && window.state.rows.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? Math.max(0, Math.min(8 * Theme.rowHeight, window.state.rows.length * rowHeight, panel.maxPanelHeight - header.implicitHeight - Theme.searchHeight - Theme.footerHeight - (notificationToolbar.visible ? notificationToolbar.implicitHeight : 0) - (notificationError.visible ? notificationError.implicitHeight + 32 : 0) - (tabs.visible ? 50 : 0) - (status.visible ? status.implicitHeight : 0) - 4)) : 0
                rows: window.state.rows
                viewKey: window.state.resultContext
                selectionIndex: window.state.selectedIndex
                rowHeight: window.notificationList ? Theme.notificationRowHeight : Theme.rowHeight
                onContentYChanged: readVisible.restart()
                onHeightChanged: readVisible.restart()
                onCountChanged: readVisible.restart()
                onSynchronizingChanged: if (!synchronizing) readVisible.restart()
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => {
                    const state = window.state;
                    const shift = event.modifiers === Qt.ShiftModifier;
                    if (!window.listNavigation || (event.modifiers !== Qt.NoModifier && !shift)) return;
                    switch (event.key) {
                    case Qt.Key_Up:
                        if (state.selectedIndex === 0) window.focusAbove();
                        else state.move(-1);
                        break;
                    case Qt.Key_Down: state.move(1); break;
                    case Qt.Key_Home: state.selectResult(0); break;
                    case Qt.Key_End: state.selectResult(state.rows.length - 1); break;
                    case Qt.Key_PageUp: window.pageResults(-1); break;
                    case Qt.Key_PageDown: window.pageResults(1); break;
                    case Qt.Key_Left: if (!state.menuBack()) return; break;
                    case Qt.Key_Right: if (!state.menuEnter()) return; break;
                    case Qt.Key_Delete: if (!state.canDismiss) return; state.dismissSelected(); break;
                    case Qt.Key_Return: case Qt.Key_Enter:
                        if (shift) state.activateSecondary(); else state.activate();
                        break;
                    case Qt.Key_Backtab: window.focusAdjacent("results", -1); break;
                    case Qt.Key_Tab: window.focusAdjacent("results", shift ? -1 : 1); break;
                    case Qt.Key_Backspace:
                        if (!state.query) { if (!state.stepBack()) return; search.forceActiveFocus(); break; }
                        state.setQuery(state.query.slice(0, -1)); search.forceActiveFocus(); break;
                    default:
                        if (!event.text || event.text.charCodeAt(0) < 32) return;
                        window.typeInSearch(event.text);
                    }
                    event.accepted = true;
                }
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Rectangle {
                    id: row
                    required property var rowData
                    readonly property var modelData: rowData
                    required property int index
                    readonly property int hint: index - list.topIndex + 1
                    width: list.width
                    height: list.rowHeight
                    color: index === window.state.selectedIndex ? Theme.selection : "transparent"
                    opacity: modelData.disabled ? 0.45 : 1
                    Rectangle { width: 3; height: parent.height - 16; y: 8; color: Theme.accent; visible: row.index === window.state.selectedIndex }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 18; rightMargin: row.modelData.notification ? 54 : 18 }
                        spacing: 14
                        Item {
                            visible: !row.modelData.notification
                            implicitWidth: 28; implicitHeight: 28
                            Image { id: icon; anchors.fill: parent; source: row.modelData.notification ? "" : row.modelData.icon || ""; sourceSize.width: 28; sourceSize.height: 28; visible: status === Image.Ready }
                            Text { anchors.centerIn: parent; visible: !icon.visible; text: (row.modelData.title || "·").slice(0, 1).toUpperCase(); color: Theme.accent; font.family: Theme.font; font.pixelSize: 17 }
                        }
                        NotificationImage {
                            visible: !!row.modelData.notification && available
                            image: row.modelData.notification ? row.modelData.icon || "" : ""
                            appIcon: row.modelData.appIcon || ""
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text { Layout.fillWidth: true; text: row.modelData.title; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; elide: Text.ElideRight; textFormat: Text.PlainText }
                            Text { Layout.fillWidth: true; text: row.modelData.subtitle || ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.small; elide: Text.ElideRight; textFormat: Text.PlainText; wrapMode: row.modelData.notification ? Text.Wrap : Text.NoWrap; maximumLineCount: row.modelData.notification ? 2 : 1 }
                            Text { Layout.fillWidth: true; visible: !!row.modelData.notification; text: row.modelData.metadata || ""; color: row.modelData.unread ? Theme.accent : Theme.muted; font.family: Theme.font; font.pixelSize: 10; elide: Text.ElideRight; textFormat: Text.PlainText }
                        }
                        Rectangle { visible: !!row.modelData.unread; implicitWidth: 5; implicitHeight: 5; color: row.modelData.critical ? Theme.danger : Theme.accent }
                        Text { visible: !!row.modelData.group; text: row.modelData.group || ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.small }
                        // ↵ on the selection, otherwise the Alt+N position.
                        Text {
                            Layout.preferredWidth: 14
                            horizontalAlignment: Text.AlignRight
                            text: row.index === window.state.selectedIndex ? "↵" : row.hint >= 1 && row.hint <= 9 && !window.state.helpMode ? String(row.hint) : ""
                            color: row.index === window.state.selectedIndex ? Theme.accent : Theme.muted
                            font.family: Theme.font; font.pixelSize: Theme.small
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPositionChanged: mouse => {
                            if (list.synchronizing || list.moving) return;
                            // Ignore geometry-only hover events when refreshed rows move beneath the pointer.
                            const point = mapToItem(list, mouse.x, mouse.y);
                            if (Math.abs(point.x - list.pointerX) < 1 && Math.abs(point.y - list.pointerY) < 1) return;
                            list.pointerX = point.x; list.pointerY = point.y;
                            window.state.selectedIndex = row.index; window.state.selectedId = row.modelData.id;
                        }
                        onClicked: mouse => {
                            window.state.selectedIndex = row.index;
                            window.state.selectedId = row.modelData.id;
                            if (mouse.button === Qt.RightButton) window.state.showActions(); else window.state.activate(row.index);
                        }
                    }
                    ActionButton {
                        visible: !!row.modelData.notification
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
                        implicitWidth: 28; implicitHeight: 28
                        text: "×"
                        Accessible.name: "Dismiss " + row.modelData.title
                        onClicked: window.notificationService.dismiss(row.modelData.id)
                    }
                }
            }
            Rectangle {
                id: status
                visible: !window.state.prompt && (!!window.state.message || window.state.loading || (window.state.rows.length === 0 && (window.state.query.length > 0 || window.state.modeId !== "apps" || window.state.pickingMode || window.state.helpMode)))
                Layout.fillWidth: true
                implicitHeight: visible ? statusRow.implicitHeight + 24 : 0
                color: Theme.surface
                RowLayout {
                    id: statusRow
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
                    Text {
                        Layout.fillWidth: true
                        text: window.state.loading ? "Working…" : window.state.message || (window.state.helpMode ? "No matching shortcuts" : window.state.completingMode ? "No matching mode" : window.notificationList ? (window.state.query.trim() ? "No matching notifications" : "No notifications") : window.state.modeId === "github" && !window.state.query ? "Type to search GitHub." : "No results")
                        color: window.state.pluginError ? Theme.danger : Theme.muted
                        font.family: Theme.font; font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    ActionButton {
                        id: retryButton
                        text: "Retry (Ctrl+R)"
                        visible: !!window.state.pluginError
                        onClicked: window.state.retry()
                        Keys.onTabPressed: window.focusAdjacent("retry", 1)
                        Keys.onBacktabPressed: window.focusAdjacent("retry", -1)
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.footerHeight
                color: Theme.surface
                RowLayout {
                    anchors { fill: parent; leftMargin: 18; rightMargin: 16 }
                    Text { text: "BORON"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2 }
                    Item { Layout.fillWidth: true }
                    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight; text: window.footerHints; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                }
            }
        }
    }
    Shortcut { sequence: "Escape"; enabled: window.visible; onActivated: window.state.goBack() }
    Shortcut { sequences: ["Ctrl+W", "Shift+Escape"]; enabled: window.visible; onActivated: window.state.close() }
    Shortcut { sequences: ["Ctrl+/", "F1"]; enabled: window.visible && !window.state.prompt; onActivated: window.state.showHelp() }
    Shortcut { sequences: ["Ctrl+N", "Alt+J"]; enabled: window.visible && !window.state.prompt; onActivated: window.state.move(1) }
    Shortcut { sequences: ["Ctrl+P", "Alt+K"]; enabled: window.visible && !window.state.prompt; onActivated: window.state.move(-1) }
    Shortcut { sequence: "Ctrl+K"; enabled: window.visible && !window.state.prompt; onActivated: window.state.showActions() }
    Shortcut { sequence: "Ctrl+Q"; enabled: window.visible && window.state.canQuitTray; onActivated: window.state.quitTray() }
    Shortcut { sequence: "Ctrl+M"; enabled: window.visible && !window.state.prompt; onActivated: window.state.showModes() }
    Shortcut { sequence: "Ctrl+D"; enabled: window.visible && window.state.canDismiss; onActivated: window.state.dismissSelected() }
    Shortcut { sequence: "Ctrl+Shift+D"; enabled: window.visible && window.state.modeId === "notifications" && window.state.browsing; onActivated: window.state.clearNotifications() }
    Shortcut { sequence: "Ctrl+R"; enabled: window.visible && !window.state.prompt && !!window.state.pluginError; onActivated: window.state.retry() }
    Shortcut { sequence: "Ctrl+Tab"; enabled: window.visible && !window.state.prompt && !window.state.actionRunning; onActivated: { if (window.listNavigation && window.state.filters.length) window.switchFilterTab(1); else window.state.cycle(1); } }
    Shortcut { sequence: "Ctrl+Shift+Tab"; enabled: window.visible && !window.state.prompt && !window.state.actionRunning; onActivated: { if (window.listNavigation && window.state.filters.length) window.switchFilterTab(-1); else window.state.cycle(-1); } }
    Shortcut { sequence: "Ctrl+PgDown"; enabled: window.visible && !window.state.prompt && !window.state.actionRunning; onActivated: window.state.cycle(1) }
    Shortcut { sequence: "Ctrl+PgUp"; enabled: window.visible && !window.state.prompt && !window.state.actionRunning; onActivated: window.state.cycle(-1) }
    Shortcut { sequence: "Alt+Left"; enabled: window.visible && window.listNavigation && window.state.filters.length > 0; onActivated: window.switchFilterTab(-1) }
    Shortcut { sequence: "Alt+Right"; enabled: window.visible && window.listNavigation && window.state.filters.length > 0; onActivated: window.switchFilterTab(1) }
    // Alt+N runs the Nth visible row; Ctrl+N switches to the Nth mode.
    Repeater {
        model: 9
        Item {
            required property int index
            Shortcut {
                sequence: "Alt+" + (index + 1)
                enabled: window.visible && !window.state.prompt && !window.state.helpMode && !window.state.actionRunning
                onActivated: window.activateVisible(index)
            }
            Shortcut {
                sequence: "Ctrl+" + (index + 1)
                enabled: window.visible && !window.state.prompt && !window.state.actionRunning && index < window.state.modes.length
                onActivated: window.state.switchModeIndex(index)
            }
        }
    }
}
