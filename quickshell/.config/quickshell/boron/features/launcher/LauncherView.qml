import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../components"

import "../devices"

Item {
    id: window
    required property var state
    readonly property Item surface: panel
    visible: state.opened
    readonly property bool deviceNavigation: state.modeId === "devices" && !state.prompt && !state.pickingMode && !state.actionRunning && !state.completingMode
    onVisibleChanged: { if (visible) Qt.callLater(() => search.forceActiveFocus()); }
    Component.onCompleted: { if (visible) Qt.callLater(() => search.forceActiveFocus()); }
    function focusResults() {
        if (!deviceNavigation || !state.rows.length) { search.forceActiveFocus(); return; }
        list.forceActiveFocus(Qt.TabFocusReason);
        list.revealSelection();
    }
    function switchDeviceTab(delta) {
        if (!deviceNavigation) return;
        const fromTabs = deviceTabs.hasTabFocus();
        const fromResults = list.activeFocus;
        state.cycleDeviceTab(delta, true);
        if (fromTabs) deviceTabs.focusSelected();
        else if (fromResults) focusResults();
        else search.forceActiveFocus();
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
                        placeholderText: window.state.pickingMode ? "Switch mode…" : window.state.modeId === "apps" ? "Search applications…" : "Search " + window.state.mode.label.toLowerCase() + "…"
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
                        Keys.onUpPressed: window.state.move(-1)
                        Keys.onDownPressed: window.state.move(1)
                        Keys.onTabPressed: event => {
                            if (window.state.completingMode) { window.state.activate(); return; }
                            if (!window.deviceNavigation) { event.accepted = false; return; }
                            deviceTabs.focusSelected(Qt.TabFocusReason);
                        }
                        Keys.onBacktabPressed: event => {
                            if (window.state.completingMode) { window.state.move(-1); return; }
                            if (!window.deviceNavigation) { event.accepted = false; return; }
                            modeButton.forceActiveFocus(Qt.BacktabFocusReason);
                        }
                    }
                    ActionButton {
                        id: modeButton
                        objectName: "launcherModeButton"
                        text: window.state.pickingMode ? "MODES" : window.state.mode.label
                        enabled: !window.state.prompt && !window.state.actionRunning
                        onClicked: window.state.showModes()
                        Keys.onTabPressed: event => {
                            if (!window.deviceNavigation) { event.accepted = false; return; }
                            search.forceActiveFocus(Qt.TabFocusReason);
                        }
                        Keys.onBacktabPressed: event => {
                            if (!window.deviceNavigation) { event.accepted = false; return; }
                            window.focusResults();
                        }
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
            RowLayout {
                id: tabs
                visible: window.state.filters.length > 0 && !window.state.prompt && !window.state.pickingMode && !window.state.completingMode
                Layout.fillWidth: true
                Layout.margins: visible ? 8 : 0
                spacing: 6
                DeviceTabs {
                    id: deviceTabs
                    objectName: "deviceTabs"
                    visible: window.state.modeId === "devices"
                    enabled: window.deviceNavigation
                    sections: visible ? window.state.filters : []
                    activeSection: window.state.activeFilter
                    onSectionRequested: section => window.state.chooseFilter(section, true)
                    onSearchRequested: search.forceActiveFocus(Qt.BacktabFocusReason)
                    onResultsRequested: window.focusResults()
                    onTextEntered: text => window.typeInSearch(text)
                }
                Repeater {
                    model: window.state.modeId === "devices" ? [] : window.state.filters
                    ActionButton {
                        required property var modelData
                        text: modelData.label
                        selected: window.state.activeFilter === modelData.id || (!window.state.activeFilter && modelData.id === "repositories")
                        enabled: !window.state.actionRunning
                        onClicked: window.state.chooseFilter(modelData.id)
                    }
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: window.state.modeId === "devices"
                    text: "Ctrl+Tab Switch · ←/→ Navigate"
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
                Layout.preferredHeight: visible ? Math.max(0, Math.min(8 * Theme.rowHeight, window.state.rows.length * Theme.rowHeight, panel.maxPanelHeight - header.implicitHeight - Theme.searchHeight - Theme.footerHeight - (tabs.visible ? 50 : 0) - (status.visible ? status.implicitHeight : 0) - 4)) : 0
                rows: window.state.rows
                viewKey: window.state.resultContext
                selectionIndex: window.state.selectedIndex
                rowHeight: Theme.rowHeight
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => {
                    if (!window.deviceNavigation || (event.modifiers !== Qt.NoModifier && event.modifiers !== Qt.ShiftModifier)) return;
                    switch (event.key) {
                    case Qt.Key_Up:
                        if (window.state.selectedIndex === 0) deviceTabs.focusSelected();
                        else window.state.move(-1);
                        break;
                    case Qt.Key_Down: window.state.move(1); break;
                    case Qt.Key_Home: window.state.selectResult(0); break;
                    case Qt.Key_End: window.state.selectResult(window.state.rows.length - 1); break;
                    case Qt.Key_PageUp: window.state.selectResult(window.state.selectedIndex - Math.max(1, Math.floor(list.height / list.rowHeight))); break;
                    case Qt.Key_PageDown: window.state.selectResult(window.state.selectedIndex + Math.max(1, Math.floor(list.height / list.rowHeight))); break;
                    case Qt.Key_Return: case Qt.Key_Enter: window.state.activate(); break;
                    case Qt.Key_Backtab: deviceTabs.focusSelected(Qt.BacktabFocusReason); break;
                    case Qt.Key_Tab:
                        if (event.modifiers & Qt.ShiftModifier) deviceTabs.focusSelected(Qt.BacktabFocusReason);
                        else modeButton.forceActiveFocus(Qt.TabFocusReason);
                        break;
                    case Qt.Key_Backspace:
                        window.state.setQuery(window.state.query.slice(0, -1)); search.forceActiveFocus(); break;
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
                    width: list.width
                    height: Theme.rowHeight
                    color: index === window.state.selectedIndex ? Theme.selection : "transparent"
                    opacity: modelData.disabled ? 0.45 : 1
                    Rectangle { width: 3; height: parent.height - 16; y: 8; color: Theme.accent; visible: row.index === window.state.selectedIndex }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                        spacing: 14
                        Item {
                            implicitWidth: 28; implicitHeight: 28
                            Image { id: icon; anchors.fill: parent; source: row.modelData.icon || ""; sourceSize.width: 28; sourceSize.height: 28; visible: status === Image.Ready }
                            Text { anchors.centerIn: parent; visible: !icon.visible; text: (row.modelData.title || "·").slice(0, 1).toUpperCase(); color: Theme.accent; font.family: Theme.font; font.pixelSize: 17 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text { Layout.fillWidth: true; text: row.modelData.title; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; elide: Text.ElideRight; textFormat: Text.PlainText }
                            Text { Layout.fillWidth: true; text: row.modelData.subtitle || ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.small; elide: Text.ElideRight; textFormat: Text.PlainText }
                        }
                        Text { text: row.index === window.state.selectedIndex ? "↵" : row.modelData.group || ""; color: row.index === window.state.selectedIndex ? Theme.accent : Theme.muted; font.family: Theme.font; font.pixelSize: Theme.small }
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
                }
            }
            Rectangle {
                id: status
                visible: !window.state.prompt && (!!window.state.message || window.state.loading || (window.state.rows.length === 0 && (window.state.query.length > 0 || window.state.modeId !== "apps" || window.state.pickingMode)))
                Layout.fillWidth: true
                implicitHeight: visible ? statusRow.implicitHeight + 24 : 0
                color: Theme.surface
                RowLayout {
                    id: statusRow
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
                    Text {
                        Layout.fillWidth: true
                        text: window.state.loading ? "Working…" : window.state.message || (window.state.completingMode ? "No matching mode" : window.state.modeId === "github" && !window.state.query ? "Type to search GitHub." : "No results")
                        color: window.state.pluginError ? Theme.danger : Theme.muted
                        font.family: Theme.font; font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    ActionButton { text: "Retry"; visible: !!window.state.pluginError; onClicked: window.state.retry() }
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
                    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight; text: window.state.completingMode ? "↑↓ Suggestions   Tab / ↵ Select mode   Esc Clear" : "↑↓ Navigate   ↵ Open   Ctrl+K Actions   Esc Back"; color: Theme.muted; font.family: Theme.font; font.pixelSize: 10 }
                }
            }
        }
    }
    Shortcut { sequence: "Escape"; enabled: window.visible; onActivated: window.state.goBack() }
    Shortcut { sequence: "Ctrl+N"; enabled: window.visible && !window.state.prompt; onActivated: window.state.move(1) }
    Shortcut { sequence: "Ctrl+P"; enabled: window.visible && !window.state.prompt; onActivated: window.state.move(-1) }
    Shortcut { sequence: "Ctrl+K"; enabled: window.visible && !window.state.prompt; onActivated: window.state.showActions() }
    Shortcut { sequence: "Ctrl+M"; enabled: window.visible && !window.state.prompt; onActivated: window.state.showModes() }
    Shortcut { sequence: "Ctrl+Tab"; enabled: window.visible && !window.state.prompt && !window.state.actionRunning; onActivated: { if (window.deviceNavigation) window.switchDeviceTab(1); else window.state.cycle(1); } }
    Shortcut { sequence: "Ctrl+Shift+Tab"; enabled: window.visible && !window.state.prompt && !window.state.actionRunning; onActivated: { if (window.deviceNavigation) window.switchDeviceTab(-1); else window.state.cycle(-1); } }
    Shortcut { sequence: "Ctrl+PgDown"; enabled: window.visible && !window.state.prompt && !window.state.actionRunning; onActivated: window.state.cycle(1) }
    Shortcut { sequence: "Ctrl+PgUp"; enabled: window.visible && !window.state.prompt && !window.state.actionRunning; onActivated: window.state.cycle(-1) }
    Shortcut { sequence: "Alt+Left"; enabled: window.visible && window.deviceNavigation; onActivated: window.switchDeviceTab(-1) }
    Shortcut { sequence: "Alt+Right"; enabled: window.visible && window.deviceNavigation; onActivated: window.switchDeviceTab(1) }
}
